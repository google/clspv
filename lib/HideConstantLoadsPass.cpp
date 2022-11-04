// Copyright 2017 The Clspv Authors. All rights reserved.
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

#include <string>

#include "llvm/ADT/DenseMap.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/AddressSpace.h"

#include "HideConstantLoadsPass.h"

using namespace llvm;
using std::string;

#define DEBUG_TYPE "hideconstantloads"

namespace {
const char *kWrapFunctionPrefix = "clspv.wrap_constant_load.";
} // namespace

string &clspv::HideConstantLoadsPass::WrapFunctionNameForType(Type *type) {
  auto where = function_for_type_.find(type);
  if (where == function_for_type_.end()) {
    // Insert it.
    auto &result = function_for_type_[type] =
        string(kWrapFunctionPrefix) + std::to_string(function_for_type_.size());
    return result;
  } else {
    return where->second;
  }
}

PreservedAnalyses clspv::HideConstantLoadsPass::run(Module &M,
                                                    ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  SmallVector<LoadInst *, 16> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (LoadInst *load = dyn_cast<LoadInst>(&I)) {
          if (clspv::AddressSpace::Constant == load->getPointerAddressSpace() ||
              clspv::AddressSpace::PushConstant ==
                  load->getPointerAddressSpace()) {
            WorkList.push_back(load);
          }
        }
      }
    }
  }

  if (WorkList.size() == 0) {
    return PA;
  }

  for (LoadInst *load : WorkList) {
    auto loadedTy = load->getType();

    // The wrap function conceptually maps the loaded value to itself.
    const string &fn_name = WrapFunctionNameForType(loadedTy);
    Function *fn = M.getFunction(fn_name);
    if (!fn) {
      // Make the function.
      FunctionType *fnTy = FunctionType::get(loadedTy, {loadedTy}, false);
      auto fn_constant = M.getOrInsertFunction(fn_name, fnTy);
      fn = cast<Function>(fn_constant.getCallee());
      fn->setOnlyReadsMemory();
    }

    // Wrap the load
    auto call = CallInst::Create(fn, {load});
    call->insertAfter(load);

    // Replace other uses of the load with the result of the wrap call.
    {
      SmallVector<User *, 16> ToReplaceIn;
      for (auto &use : load->uses()) {
        User *user = use.getUser();
        ToReplaceIn.push_back(user);
      }
      for (auto *user : ToReplaceIn) {
        if (dyn_cast<CallInst>(user) != call) {
          user->replaceUsesOfWith(load, call);
        }
      }
    }
  }

  return PA;
}

PreservedAnalyses clspv::UnhideConstantLoadsPass::run(Module &M,
                                                      ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  SmallVector<Function *, 16> WorkList;
  for (auto &F : M.getFunctionList()) {
    if (F.getName().startswith(kWrapFunctionPrefix)) {
      WorkList.push_back(&F);
    }
  }

  if (WorkList.size() == 0)
    return PA;

  SmallVector<CallInst *, 16> RemoveList;
  for (auto *F : WorkList) {
    for (auto &use : F->uses()) {
      if (auto *call = dyn_cast<CallInst>(use.getUser())) {
        assert(call->arg_size() == 1);
        auto *load = call->getArgOperand(0);
        call->replaceAllUsesWith(load);
        RemoveList.push_back(call);
      }
    }
  }
  for (auto *call : RemoveList) {
    call->eraseFromParent();
  }
  for (auto *F : WorkList) {
    F->eraseFromParent();
  }

  return PA;
}
