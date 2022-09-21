// Copyright 2022 The Clspv Authors. All rights reserved.
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

#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "InlineFuncWithImageMetadataGetterPass.h"

using namespace llvm;

#define DEBUG_TYPE "inlinefuncwithimagemetadatagetterpass"

PreservedAnalyses
clspv::InlineFuncWithImageMetadataGetterPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  // Loop through our inline pass until they stop changing thing.
  bool changed = true;
  while (changed) {
    changed &= InlineFunctions(M);
  }

  return PA;
}

static bool FunctionShouldBeInlined(Function &F) {
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      // If we have a call instruction...
      if (auto call = dyn_cast<CallInst>(&I)) {
        // ...which is calling image_channel_order or image_channel_datatype
        auto Name = call->getCalledFunction()->getName();
        if (Name.contains("get_image_channel_order") ||
            Name.contains("get_image_channel_data_type")) {
          return true;
        }
      }
    }
  }
  return false;
}

bool clspv::InlineFuncWithImageMetadataGetterPass::InlineFunctions(Module &M) {
  bool Changed = false;

  UniqueVector<CallInst *> WorkList;
  std::set<Function *> FunctionToInline;
  for (Function &F : M) {
    if (F.isDeclaration() || F.getCallingConv() == CallingConv::SPIR_KERNEL) {
      continue;
    }
    if (FunctionShouldBeInlined(F)) {
      FunctionToInline.insert(&F);
    }
  }

  if (FunctionToInline.empty()) {
    return false;
  }

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // If we have a call instruction...
        if (auto call = dyn_cast<CallInst>(&I)) {
          // ...which is calling a function to inline
          if (FunctionToInline.count(call->getCalledFunction()) > 0) {
            WorkList.insert(call);
          }
        }
      }
    }
  }

  for (CallInst *Call : WorkList) {
    InlineFunctionInfo IFI;
    Changed |= InlineFunction(*Call, IFI, false, nullptr, false).isSuccess();
  }

  return Changed;
}
