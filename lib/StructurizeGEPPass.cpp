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

#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include "Builtins.h"
#include "StructurizeGEPPass.h"

using namespace llvm;

PreservedAnalyses clspv::StructurizeGEPPass::run(Module &M,
                                                 ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  bool Changed = false;

  SmallVector<GetElementPtrInst *, 16> Worklist;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
          Worklist.push_back(GEP);
        }
      }
    }
  }

  for (GetElementPtrInst *GEP : Worklist) {
    IRBuilder<> Builder(GEP);
    SmallVector<Value *, 8> Indices(GEP->indices());
    CallInst *SGEP = Builder.CreateStructuredGEP(
        GEP->getSourceElementType(), GEP->getPointerOperand(), Indices);

    // CreateStructuredGEP might not set name, do it manually
    SGEP->setName(GEP->getName());

    GEP->replaceAllUsesWith(SGEP);
    GEP->eraseFromParent();
    Changed = true;
  }

  return Changed ? PA : PreservedAnalyses::all();
}
