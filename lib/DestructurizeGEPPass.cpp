// Copyright 2026 The Clspv Authors. All rights reserved.
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

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"

#include "DestructurizeGEPPass.h"

using namespace llvm;

PreservedAnalyses clspv::DestructurizeGEPPass::run(Module &M,
                                                   ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  bool Changed = false;

  SmallVector<CallInst *, 16> Worklist;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *Call = dyn_cast<CallInst>(&I)) {
          if (Call->getIntrinsicID() == Intrinsic::structured_gep) {
            Worklist.push_back(Call);
          }
        }
      }
    }
  }

  for (CallInst *Call : Worklist) {
    IRBuilder<> Builder(Call);
    Type *SourceTy = Call->getParamElementType(0);
    Value *Ptr = Call->getArgOperand(0);
    SmallVector<Value *, 8> Indices;
    for (unsigned i = 1; i < Call->arg_size(); ++i) {
      Indices.push_back(Call->getArgOperand(i));
    }

    Value *GEP = Builder.CreateGEP(SourceTy, Ptr, Indices, Call->getName());

    Call->replaceAllUsesWith(GEP);
    Call->eraseFromParent();
    Changed = true;
  }

  return Changed ? PA : PreservedAnalyses::all();
}
