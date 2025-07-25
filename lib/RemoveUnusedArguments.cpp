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

#include "llvm/IR/CallingConv.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/Option.h"

#include "RemoveUnusedArguments.h"

using namespace llvm;

PreservedAnalyses clspv::RemoveUnusedArguments::run(Module &M,
                                                    ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  std::vector<Candidate> candidates;
  findCandidates(M, &candidates);
  removeUnusedParameters(M, candidates);

  return PA;
}

bool clspv::RemoveUnusedArguments::findCandidates(
    Module &M, std::vector<Candidate> *candidates) {
  bool changed = false;
  for (auto &F : M) {
    // Don't modify kernel functions.
    if (F.isDeclaration() || F.getCallingConv() == CallingConv::SPIR_KERNEL)
      continue;

    if (F.getFunctionType()->isVarArg())
      continue;

    bool local_changed = false;
    SmallVector<Value *, 8> args;
    for (auto &Arg : F.args()) {
      if (Arg.use_empty()) {
        local_changed = true;
        args.push_back(nullptr);
      } else {
        args.push_back(&Arg);
      }
    }

    if (local_changed) {
      candidates->push_back({&F, args});
      changed = true;
    }
  }

  return changed;
}

void clspv::RemoveUnusedArguments::removeUnusedParameters(
    Module &M, const std::vector<Candidate> &candidates) {
  for (auto &candidate : candidates) {
    Function *f = candidate.function;
    f->removeFromParent();

    // Rebuild the type.
    auto fn_attrs = f->getAttributes();
    SmallVector<Type *, 8> arg_types;
    uint32_t idx = 0;
    for (auto *arg : candidate.args) {
      if (arg) {
        arg_types.push_back(arg->getType());
      } else {
        // Remove any parameter attributes for deleted args.
        fn_attrs = fn_attrs.removeParamAttributes(M.getContext(), idx);
      }
      idx++;
    }
    FunctionType *new_type =
        FunctionType::get(f->getReturnType(), arg_types, false);

    // Insert the new function. Copy the calling convention, attributes and
    // metadata.
    auto inserted =
        M.getOrInsertFunction(f->getName(), new_type, fn_attrs).getCallee();
    Function *new_function = cast<Function>(inserted);
    new_function->setCallingConv(f->getCallingConv());
    new_function->copyMetadata(f, 0);

    // Move the basic blocks into the new function.
    if (!f->isDeclaration()) {
      std::vector<BasicBlock *> blocks;
      for (auto &BB : *f) {
        blocks.push_back(&BB);
      }
      for (auto *BB : blocks) {
        BB->removeFromParent();
        BB->insertInto(new_function);
      }
    }

    // Replace uses of remaining args.
    auto new_arg_iter = new_function->arg_begin();
    for (size_t old_arg_index = 0; old_arg_index < candidate.args.size();
         ++old_arg_index) {
      if (auto *arg = candidate.args[old_arg_index]) {
        arg->replaceAllUsesWith(&*new_arg_iter);
        ++new_arg_iter;
      }
    }

    // Update calls to the old function.
    std::vector<User *> users;
    for (auto *U : f->users()) {
      users.push_back(U);
    }

    for (auto *U : users) {
      if (auto *call = dyn_cast<CallInst>(U)) {
        SmallVector<Value *, 8> args;
        for (size_t i = 0; i < candidate.args.size(); ++i) {
          if (candidate.args[i]) {
            args.push_back(call->getOperand(i));
          }
        }
        CallInst *new_call = CallInst::Create(new_type, new_function, args, "",
                                              call->getIterator());
        new_call->takeName(call);
        call->replaceAllUsesWith(new_call);
        call->eraseFromParent();
      }
    }

    // Now we can delete the old version.
    delete f;
  }
}
