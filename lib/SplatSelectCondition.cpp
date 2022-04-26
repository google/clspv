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

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "Passes.h"

using namespace llvm;

#define DEBUG_TYPE "splatselectcond"

PreservedAnalyses
clspv::SplatSelectConditionPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  SmallVector<SelectInst *, 16> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (SelectInst *sel = dyn_cast<SelectInst>(&I)) {
          auto cond = sel->getCondition();
          if (cond->getType()->isIntegerTy(1)) {
            Type *valueTy = sel->getTrueValue()->getType();
            if (valueTy->isVectorTy()) {
              WorkList.push_back(sel);
            }
          }
        }
      }
    }
  }

  if (WorkList.size() == 0)
    return PA;

  IRBuilder<> Builder(WorkList.front());

  for (SelectInst *sel : WorkList) {
    auto cond = sel->getCondition();
    auto numElems = cast<VectorType>(sel->getTrueValue()->getType())
                        ->getElementCount()
                        .getKnownMinValue();
    Builder.SetInsertPoint(sel);
    auto splat = Builder.CreateVectorSplat(numElems, cond);
    sel->setCondition(splat);
  }

  return PA;
}
