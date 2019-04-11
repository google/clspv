// Copyright 2019 The Clspv Authors. All rights reserved.
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
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/CallingConv.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "clspv/Passes.h"

#include "ArgKind.h"
#include "CallGraphOrderedFunctions.h"
#include "Constants.h"

using namespace llvm;

namespace {

class MultiVersionUBOFunctionsPass final : public ModulePass {
public:
  static char ID;
  MultiVersionUBOFunctionsPass() : ModulePass(ID) {}
  bool runOnModule(Module &M) override;

private:
  // Struct for tracking specialization information.
  struct ResourceInfo {
    // The specific argument.
    Argument *arg;
    // The resource var base call.
    CallInst *base;
    // Series of GEPs that operate on |base|.
    std::vector<GetElementPtrInst *> indices;
  };

  // Analyzes the call, |user|, to |fn| in terms of its UBO arguments. Returns
  // true if |user| can be transformed into a specialized function.
  //
  // Currently, this function is only successful in analyzing GEP chains to a
  // resource variable.
  bool AnalyzeCall(Function *fn, CallInst *user,
                   std::vector<ResourceInfo> *resources);

  // Inlines |call|.
  void InlineCallSite(CallInst *call);

  // Transforms the call to |fn| into a specialized call based on |resources|.
  // Replaces |call| with a call to the specialized version.
  void SpecializeCall(Function *fn, CallInst *call,
                      const std::vector<ResourceInfo> &resources, size_t id);

  // Adds extra arguments to |fn| by rebuilding the entire function.
  Function *AddExtraArguments(Function *fn,
                              const std::vector<Value *> &extra_args);
};

} // namespace

char MultiVersionUBOFunctionsPass::ID = 0;
static RegisterPass<MultiVersionUBOFunctionsPass>
    X("MultiVersionUBOFunctionsPass",
      "Multi-version functions with UBO params");

namespace clspv {
ModulePass *createMultiVersionUBOFunctionsPass() {
  return new MultiVersionUBOFunctionsPass();
}
} // namespace clspv

bool MultiVersionUBOFunctionsPass::runOnModule(Module &M) {
  bool changed = false;
  UniqueVector<Function *> ordered_functions =
      clspv::CallGraphOrderedFunctions(M);

  for (auto fn : ordered_functions) {
    // Kernels don't need modified.
    if (fn->isDeclaration() || fn->getCallingConv() == CallingConv::SPIR_KERNEL)
      continue;

    bool local_changed = false;
    size_t count = 0;
    for (auto user : fn->users()) {
      if (auto call = dyn_cast<CallInst>(user)) {
        std::vector<ResourceInfo> resources;
        if (AnalyzeCall(fn, call, &resources)) {
          if (!resources.empty()) {
            local_changed = true;
            SpecializeCall(fn, call, resources, count++);
          }
        } else {
          local_changed = true;
          InlineCallSite(call);
        }
      }
    }

    fn->removeDeadConstantUsers();
    if (local_changed) {
      // All calls to this function were either specialized or inlined.
      fn->eraseFromParent();
    }
    changed |= local_changed;
  }

  return changed;
}

bool MultiVersionUBOFunctionsPass::AnalyzeCall(
    Function *fn, CallInst *user, std::vector<ResourceInfo> *resources) {
  for (auto &arg : fn->args()) {
    if (clspv::GetArgKindForType(arg.getType()) != clspv::ArgKind::BufferUBO)
      continue;

    Value *arg_operand = user->getOperand(arg.getArgNo());
    ResourceInfo info;
    info.arg = &arg;

    DenseSet<Value *> visited;
    std::vector<Value *> stack;
    stack.push_back(arg_operand);

    while (!stack.empty()) {
      Value *value = stack.back();
      stack.pop_back();

      if (!visited.insert(value).second)
        continue;

      if (CallInst *call = dyn_cast<CallInst>(value)) {
        if (call->getCalledFunction()->getName().startswith(
                clspv::ResourceAccessorFunction())) {
          info.base = call;
        } else {
          // Unknown function call returning a constant pointer requires
          // inlining.
          return false;
        }
      } else if (auto gep = dyn_cast<GetElementPtrInst>(value)) {
        info.indices.push_back(gep);
        stack.push_back(gep->getOperand(0));
      } else {
        // Unhandled instruction requires inlining.
        return false;
      }
    }

    resources->push_back(std::move(info));
  }

  return true;
}

void MultiVersionUBOFunctionsPass::InlineCallSite(CallInst *call) {
  InlineFunctionInfo IFI;
  CallSite CS(call);
  InlineFunction(CS, IFI, nullptr, false);
}

void MultiVersionUBOFunctionsPass::SpecializeCall(
    Function *fn, CallInst *call, const std::vector<ResourceInfo> &resources,
    size_t id) {

  // The basis of the specialization is a clone of |fn|, however, the clone may
  // need rebuilt in order to receive extra arguments.
  ValueToValueMapTy remapped;
  auto *clone = CloneFunction(fn, remapped);
  std::string name;
  raw_string_ostream str(name);
  str << fn->getName() << "_clspv_" << id;
  clone->setName(str.str());

  std::vector<Value *> extra_args;
  for (auto info : resources) {
    // Must traverse the GEPs in reverse order to match how the code will be
    // generated below so that the iterator for the extra arguments is
    // consistent.
    for (auto iter = info.indices.rbegin(); iter != info.indices.rend();
         ++iter) {
      // Skip pointer operand.
      auto *idx = *iter;
      for (size_t i = 1; i < idx->getNumOperands(); ++i) {
        Value *operand = idx->getOperand(i);
        if (!isa<Constant>(operand)) {
          extra_args.push_back(operand);
        }
      }
    }
  }

  if (!extra_args.empty()) {
    // Need to add extra arguments to this function.
    clone = AddExtraArguments(clone, extra_args);
  }

  auto where = clone->begin()->begin();
  while (isa<AllocaInst>(where)) {
    ++where;
  }

  IRBuilder<> builder(&*where);
  auto new_arg_iter = clone->arg_begin();
  for (auto &arg : fn->args()) {
    ++new_arg_iter;
  }
  for (auto info : resources) {
    // Create the resource var function.
    SmallVector<Value *, 8> operands;
    for (size_t i = 0; i < info.base->getNumOperands() - 1; ++i)
      operands.push_back(info.base->getOperand(i));
    CallInst *resource_fn =
        builder.CreateCall(info.base->getCalledFunction(), operands);

    // Create the chain of GEPs. Traversed in reverse order because we added
    // them from use to def.
    Value *ptr = resource_fn;
    for (auto iter = info.indices.rbegin(); iter != info.indices.rend();
         ++iter) {
      SmallVector<Value *, 8> indices;
      for (size_t i = 1; i != (*iter)->getNumOperands(); ++i) {
        Value *operand = (*iter)->getOperand(i);
        if (isa<Constant>(operand)) {
          indices.push_back(operand);
        } else {
          // Each extra argument is unique so the iterator is "consumed".
          indices.push_back(&*new_arg_iter);
          ++new_arg_iter;
        }
      }
      ptr = builder.CreateGEP(ptr, indices);
    }

    // Now replace the use of the argument with the result GEP.
    Value *remapped_arg = remapped.lookup(info.arg);
    remapped_arg->replaceAllUsesWith(ptr);
  }

  // Replace the call with a call to the newly specialized function.
  SmallVector<Value *, 16> new_args;
  for (size_t i = 0; i < call->getNumOperands() - 1; ++i) {
    new_args.push_back(call->getOperand(i));
  }
  for (auto extra : extra_args) {
    new_args.push_back(extra);
  }
  auto *replacement = CallInst::Create(clone, new_args, "", call);
  call->replaceAllUsesWith(replacement);
  call->eraseFromParent();
}

Function *MultiVersionUBOFunctionsPass::AddExtraArguments(
    Function *fn, const std::vector<Value *> &extra_args) {
  // Generate the new function type.
  SmallVector<Type *, 8> arg_types;
  for (auto &arg : fn->args()) {
    arg_types.push_back(arg.getType());
  }
  for (auto v : extra_args) {
    arg_types.push_back(v->getType());
  }
  FunctionType *new_type =
      FunctionType::get(fn->getReturnType(), arg_types, fn->isVarArg());

  // Insert the new function and copy calling conv, attributes and metadata.
  auto *module = fn->getParent();
  fn->removeFromParent();
  auto pair =
      module->getOrInsertFunction(fn->getName(), new_type, fn->getAttributes());
  Function *new_function = cast<Function>(pair.getCallee());
  new_function->setCallingConv(fn->getCallingConv());
  new_function->copyMetadata(fn, 0);

  // Move the basic blocks into the new function
  if (!fn->isDeclaration()) {
    std::vector<BasicBlock *> blocks;
    for (auto &BB : *fn) {
      blocks.push_back(&BB);
    }
    for (auto *BB : blocks) {
      BB->removeFromParent();
      BB->insertInto(new_function);
    }
  }

  // Replace arg uses.
  for (auto old_arg_iter = fn->arg_begin(),
            new_arg_iter = new_function->arg_begin();
       old_arg_iter != fn->arg_end(); ++old_arg_iter, ++new_arg_iter) {
    old_arg_iter->replaceAllUsesWith(&*new_arg_iter);
  }

  // There are no calls to |fn| yet so we don't need to worry about updating
  // calls.

  delete fn;
  return new_function;
}
