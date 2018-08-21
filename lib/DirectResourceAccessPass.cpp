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
#include "llvm/Support/raw_ostream.h"

#include "clspv/Option.h"
#include "clspv/Passes.h"

#include "ArgKind.h"
#include "Constants.h"

using namespace llvm;

#define DEBUG_TYPE "directresourceaccess"

namespace {

cl::opt<bool> ShowDRA("show-dra", cl::init(false), cl::Hidden,
                      cl::desc("Show direct resource access details"));

using SamplerMapType = llvm::ArrayRef<std::pair<unsigned, std::string>>;

class DirectResourceAccessPass final : public ModulePass {
public:
  static char ID;
  DirectResourceAccessPass() : ModulePass(ID) {}
  bool runOnModule(Module &M) override;

private:
  // Return the functions reachable from entry point functions, where
  // callers appear before callees.  OpenCL C does not permit recursion
  // or function or pointers, so this is always well defined.  The ordering
  // should be reproducible from one run to the next.
  UniqueVector<Function *> CallGraphOrderedFunctions(Module &);

  // For each kernel argument that will map to a resource variable (descriptor),
  // try to rewrite the uses of the argument as a direct access of the resource.
  // We can only do this if all the callees of the function use the same
  // resource access value for that argument.  Returns true if the module
  // changed.
  bool RewriteResourceAccesses(Function *fn);

  // Rewrite uses of this resrouce-based arg if all the callers pass in the
  // same resource access.  Returns true if the module changed.
  bool RewriteAccessesForArg(Function *fn, int arg_index, Argument &arg);
};
} // namespace

char DirectResourceAccessPass::ID = 0;
static RegisterPass<DirectResourceAccessPass> X("DirectResourceAccessPass",
                                                "Direct resource access");

namespace clspv {
ModulePass *createDirectResourceAccessPass() {
  return new DirectResourceAccessPass();
}
} // namespace clspv

namespace {
bool DirectResourceAccessPass::runOnModule(Module &M) {
  bool Changed = false;

  if (clspv::Option::DirectResourceAccess()) {
    auto ordered_functions = CallGraphOrderedFunctions(M);
    for (auto *fn : ordered_functions) {
      Changed |= RewriteResourceAccesses(fn);
    }
  }

  return Changed;
}

UniqueVector<Function *>
DirectResourceAccessPass::CallGraphOrderedFunctions(Module &M) {
  // Use a topological sort.

  // Make an ordered list of all functions having bodies, with kernel entry
  // points listed first.
  UniqueVector<Function *> functions;
  SmallVector<Function *, 10> entry_points;
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    if (F.getCallingConv() == CallingConv::SPIR_KERNEL) {
      functions.insert(&F);
      entry_points.push_back(&F);
    }
  }
  // Add the remaining functions.
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    if (F.getCallingConv() != CallingConv::SPIR_KERNEL) {
      functions.insert(&F);
    }
  }

  // This will be a complete set of reveresed edges, i.e. with all pairs
  // of (callee, caller).
  using Edge = std::pair<unsigned, unsigned>;
  auto make_edge = [&functions](Function *callee, Function *caller) {
    return std::pair<unsigned, unsigned>{functions.idFor(callee),
                                         functions.idFor(caller)};
  };
  std::set<Edge> reverse_edges;
  // Map each function to the functions it calls, and populate |reverse_edges|.
  std::map<Function *, SmallVector<Function *, 3>> calls_functions;
  for (Function *callee : functions) {
    for (auto &use : callee->uses()) {
      if (auto *call = dyn_cast<CallInst>(use.getUser())) {
        Function *caller = call->getParent()->getParent();
        calls_functions[caller].push_back(callee);
        reverse_edges.insert(make_edge(callee, caller));
      }
    }
  }
  // Sort the callees in module-order.  This helps us produce a deterministic
  // result.
  for (auto &pair : calls_functions) {
    auto &callees = pair.second;
    std::sort(callees.begin(), callees.end(),
              [&functions](Function *lhs, Function *rhs) {
                return functions.idFor(lhs) < functions.idFor(rhs);
              });
  }

  // Use Kahn's algorithm for topoological sort.
  UniqueVector<Function *> result;
  SmallVector<Function *, 10> work_list(entry_points.begin(),
                                        entry_points.end());
  while (!work_list.empty()) {
    Function *caller = work_list.back();
    work_list.pop_back();
    result.insert(caller);
    auto &callees = calls_functions[caller];
    for (auto *callee : callees) {
      reverse_edges.erase(make_edge(callee, caller));
      auto lower_bound = reverse_edges.lower_bound(make_edge(callee, nullptr));
      if (lower_bound == reverse_edges.end() ||
          lower_bound->first != functions.idFor(callee)) {
        // Callee has no other unvisited callers.
        work_list.push_back(callee);
      }
    }
  }
  // If reverse_edges is not empty then there was a cycle.  But we don't care
  // about that erroneous case.

  if (ShowDRA) {
    outs() << "DRA: Ordered functions:\n";
    for (Function *fun : result) {
      outs() << "DRA:   " << fun->getName() << "\n";
    }
  }
  return result;
}

bool DirectResourceAccessPass::RewriteResourceAccesses(Function *fn) {
  bool Changed = false;
  int arg_index = 0;
  for (Argument &arg : fn->args()) {
    switch (clspv::GetArgKindForType(arg.getType())) {
    case clspv::ArgKind::Buffer:
    case clspv::ArgKind::ReadOnlyImage:
    case clspv::ArgKind::WriteOnlyImage:
    case clspv::ArgKind::Sampler:
    case clspv::ArgKind::Local:
      Changed |= RewriteAccessesForArg(fn, arg_index, arg);
      break;
    default:
      // Should not happen
      break;
    }
    arg_index++;
  }
  return Changed;
}

bool DirectResourceAccessPass::RewriteAccessesForArg(Function *fn,
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
    // builtin function. (@clspv.resource.var.* or @clspv.local.var.*)
    Value *base;
    // The descriptor set.
    uint32_t set;
    // The binding.
    uint32_t binding;
    // If the parameter is a GEP, then this is the number of zero-indices
    // the GEP used.
    unsigned num_gep_zeroes;
    // An example call fitting
    CallInst *sample_call;
  };
  // The common valid parameter info across all the callers seen soo far.

  bool seen_one = false;
  ParamInfo common;
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
        if (call->getCalledFunction()->getName().startswith(
                clspv::ResourceAccessorFunction())) {
          const auto set = uint32_t(
              dyn_cast<ConstantInt>(call->getOperand(0))->getZExtValue());
          const auto binding = uint32_t(
              dyn_cast<ConstantInt>(call->getOperand(1))->getZExtValue());
          if (!merge_param_info({call->getCalledFunction(), set, binding,
                                 num_gep_zeroes, call}))
            return false;
        } else if (call->getCalledFunction()->getName().startswith(
                      clspv::WorkgroupAccessorFunction())) {
          const uint32_t spec_id = uint32_t(
              dyn_cast<ConstantInt>(call->getOperand(0))->getZExtValue());
          if (!merge_param_info({call->getCalledFunction(), spec_id, 0,
                                 num_gep_zeroes, call}))
            return false;
        } else {
          // A call but not to a resource access builtin function.
          return false;
        }
      } else if (isa<GlobalValue>(value)) {
        if (!merge_param_info({value, 0, 0, num_gep_zeroes, nullptr}))
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
      if (common.sample_call) outs() << *common.sample_call << "\n";
      else outs() << "nullptr\n";
    }
  }

  // Now rewrite the argument, using the info in |common|.

  Changed = true;
  IRBuilder<> Builder(fn->getParent()->getContext());
  auto *zero = Builder.getInt32(0);
  Builder.SetInsertPoint(fn->getEntryBlock().getFirstNonPHI());

  Value *replacement = common.base;
  if (Function* function = dyn_cast<Function>(replacement)) {
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
    replacement = GetElementPtrInst::Create(nullptr, replacement, zeroes);
    Builder.Insert(cast<Instruction>(replacement));
    if (ShowDRA) {
      outs() << "DRA:    Replace: gep  " << *replacement << "\n";
    }
  }
  arg.replaceAllUsesWith(replacement);

  return Changed;
}

} // namespace
