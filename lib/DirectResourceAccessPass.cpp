// Copyright 2018 The Clspv Authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <climits>
#include <map>
#include <set>
#include <utility>
#include <vector>

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/Option.h"

#include "ArgKind.h"
#include "Builtins.h"
#include "CallGraphOrderedFunctions.h"
#include "Constants.h"
#include "DirectResourceAccessPass.h"

using namespace llvm;

#define DEBUG_TYPE "directresourceaccess"

namespace {

cl::opt<bool> ShowDRA("show-dra", cl::init(false), cl::Hidden,
                      cl::desc("Show direct resource access details"));

} // namespace

PreservedAnalyses
clspv::DirectResourceAccessPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  if (clspv::Option::DirectResourceAccess()) {
    auto ordered_functions = clspv::CallGraphOrderedFunctions(M);
    if (ShowDRA) {
      outs() << "DRA: Ordered functions:\n";
      for (Function *fun : ordered_functions) {
        outs() << "DRA:   " << fun->getName() << "\n";
      }
    }

    for (auto *fn : ordered_functions) {
      RewriteResourceAccesses(fn);
    }
  }

  return PA;
}

bool clspv::DirectResourceAccessPass::RewriteResourceAccesses(Function *fn) {
  bool Changed = false;
  int arg_index = 0;
  for (Argument &arg : fn->args()) {
    switch (clspv::GetArgKind(arg)) {
    case clspv::ArgKind::Buffer:
    case clspv::ArgKind::BufferUBO:
    case clspv::ArgKind::SampledImage:
    case clspv::ArgKind::StorageImage:
    case clspv::ArgKind::Sampler:
    case clspv::ArgKind::Local:
      Changed |= RewriteAccessesForArg(fn, arg_index, arg);
      break;
    case clspv::ArgKind::Pod:
    case clspv::ArgKind::PodUBO:
    case clspv::ArgKind::PodPushConstant:
      // These are represented by structs. Don't rewrite them.
      break;
    default:
      errs() << "Unhandled ArgKind in "
                "clspv::DirectResourceAccessPass::RewriteResourceAccesses: "
             << int(clspv::GetArgKind(arg)) << "\n";
      llvm_unreachable(
          "Unhandled ArgKind in "
          "clspv::DirectResourceAccessPass::RewriteResourceAccesses");
      break;
    }
    arg_index++;
  }
  return Changed;
}

// Rewrites, if possible, all the arg_index'th arg to all callers to 'fn',
// to replace passing the resource by pointer argument to directly accessing
// the underlying global variable for the resource.  This is only possible
// when all callers call 'fn' with the same underlying resource variable.
// Returns true if a change was made.
bool clspv::DirectResourceAccessPass::RewriteAccessesForArg(Function *fn,
                                                            int arg_index,
                                                            Argument &arg) {
  bool Changed = false;
  if (fn->use_empty()) {
    return false;
  }

  // We can convert a parameter to a direct resource access if it is
  // either a direct call to a clspv.resource.var.* or if it a GEP of
  // such a thing (where the GEP can only have zero indices).
  struct ParamInfo {
    // The base value. It is either a global variable or a resource-access
    // builtin function (clspv.resource.var.* or clspv.local.var.*).
    Value *base;
    // The descriptor set.
    uint32_t set;
    // The binding.
    uint32_t binding;
    // If base is a resource, then this is the resource type.
    // If base is a pointer-to-local, then this is the array type.
    // If base is a global value, then this is the value type (the type stored
    // in the global value).
    Type *pointee_type;
    // If the call parameter is a GEP, then this is the number of zero-indices
    // the GEP used.
    unsigned num_gep_zeroes;
    // A sample call using this function argument as the resource described
    // above.
    CallInst *sample_call;
  };

  // The common valid parameter info across all the callers seen so far.
  ParamInfo common;
  bool seen_one = false;

  // Tries to merge the given parameter info into |common|.  If it is the first
  // time we've tried, then save it.  Returns true if there is no conflict.
  auto merge_param_info = [&seen_one, &common](const ParamInfo &pi) {
    if (!seen_one) {
      common = pi;
      seen_one = true;
      return true;
    }
    return pi.base == common.base && pi.set == common.set &&
           pi.binding == common.binding &&
           pi.num_gep_zeroes == common.num_gep_zeroes;
  };

  for (auto &use : fn->uses()) {
    if (auto *caller = dyn_cast<CallInst>(use.getUser())) {
      Value *value = caller->getArgOperand(arg_index);
      // We care about two cases:
      //     - a direct call to clspv.resource.var.*
      //     - a GEP with only zero indices, where the base pointer is
      //       direct call to @clspv.resource.var.* or clspv.local.var.*,
      //       or is a global value for a workgroup variable.

      // Unpack GEPs with zeros, if we can.  Rewrite |value| as we go along.
      unsigned num_gep_zeroes = 0;
      bool first_gep = true;
      for (auto *gep = dyn_cast<GetElementPtrInst>(value); gep;
           gep = dyn_cast<GetElementPtrInst>(value)) {
        if (!gep->hasAllZeroIndices()) {
          return false;
        }
        // If not the first GEP, then ignore the "element" index (which I call
        // "slide") since that will be combined with the last index of the
        // previous GEP.
        num_gep_zeroes += gep->getNumIndices() + (first_gep ? 0 : -1);
        value = gep->getPointerOperand();
        first_gep = false;
      }
      if (auto *call = dyn_cast<CallInst>(value)) {
        // If the call is a call to a @clspv.resource.var.* function, then try
        // to merge it, assuming the given number of GEP zero-indices so far.
        auto *callee = call->getCalledFunction();
        auto &func_info = clspv::Builtins::Lookup(callee);
        if (func_info.getType() == clspv::Builtins::kClspvResource) {
          const auto set = uint32_t(
              dyn_cast<ConstantInt>(
                  call->getOperand(clspv::ClspvOperand::kResourceDescriptorSet))
                  ->getZExtValue());
          const auto binding = uint32_t(
              dyn_cast<ConstantInt>(
                  call->getOperand(clspv::ClspvOperand::kResourceBinding))
                  ->getZExtValue());
          auto *resource_type =
              call->getOperand(clspv::ClspvOperand::kResourceDataType)
                  ->getType();
          if (!merge_param_info(
                  {callee, set, binding, resource_type, num_gep_zeroes, call}))
            return false;
        } else if (func_info.getType() == clspv::Builtins::kClspvLocal) {
          const uint32_t spec_id = uint32_t(
              dyn_cast<ConstantInt>(
                  call->getOperand(clspv::ClspvOperand::kWorkgroupSpecId))
                  ->getZExtValue());
          auto *array_ty =
              call->getOperand(clspv::ClspvOperand::kWorkgroupDataType)
                  ->getType();
          if (!merge_param_info(
                  {callee, spec_id, 0, array_ty, num_gep_zeroes, call}))
            return false;
        } else {
          // A call but not to a resource access builtin function.
          return false;
        }
      } else if (auto *gv = dyn_cast<GlobalValue>(value)) {
        // This occurs when there a __local variable is declared inside a
        // function. (Are there other times?)
        if (!merge_param_info(
                {value, 0, 0, gv->getValueType(), num_gep_zeroes, nullptr}))
          return false;
      } else {
        // Not a call.
        return false;
      }
    } else {
      // There isn't enough commonality.  Bail out without changing anything.
      return false;
    }
  }
  if (ShowDRA) {
    if (seen_one) {
      outs() << "DRA:  Rewrite " << fn->getName() << " arg " << arg_index << " "
             << arg.getName() << ": " << common.base->getName() << " ("
             << common.set << "," << common.binding
             << ") zeroes: " << common.num_gep_zeroes << " sample-call ";
      if (common.sample_call)
        outs() << *common.sample_call << "\n";
      else
        outs() << "nullptr\n";
    }
  }

  // Now rewrite the argument, using the info in |common|.

  Changed = true;
  IRBuilder<> Builder(fn->getParent()->getContext());
  auto *zero = Builder.getInt32(0);
  Builder.SetInsertPoint(fn->getEntryBlock().getFirstNonPHI());

  Value *replacement = common.base;
  if (Function *function = dyn_cast<Function>(replacement)) {
    // Create the call.
    SmallVector<Value *, 8> args(common.sample_call->arg_begin(),
                                 common.sample_call->arg_end());
    replacement = Builder.CreateCall(function, args);
    if (ShowDRA) {
      outs() << "DRA:    Replace: call " << *replacement << "\n";
    }
  }
  if (common.num_gep_zeroes) {
    SmallVector<Value *, 3> zeroes;
    for (unsigned i = 0; i < common.num_gep_zeroes; i++) {
      zeroes.push_back(zero);
    }
    // Builder.CreateGEP is not used to avoid creating a GEPConstantExpr in the
    // case of global variables.
    replacement =
        GetElementPtrInst::Create(common.pointee_type, replacement, zeroes);
    Builder.Insert(cast<Instruction>(replacement));
    if (ShowDRA) {
      outs() << "DRA:    Replace: gep  " << *replacement << "\n";
    }
  }
  arg.replaceAllUsesWith(replacement);

  return Changed;
}
