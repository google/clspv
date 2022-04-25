// Copyright 2020 The Clspv Authors. All rights reserved.
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

#include <vector>

#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"

#include "StripFreezePass.h"

#define DEBUG_TYPE "stripfreeze"

using namespace llvm;

PreservedAnalyses clspv::StripFreezePass::run(Module &M,
                                              ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  std::vector<Instruction *> dead;
  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        if (auto freeze = dyn_cast<FreezeInst>(&I)) {
          freeze->replaceAllUsesWith(freeze->getOperand(0));
          dead.push_back(freeze);
        }
      }
    }
  }

  for (auto inst : dead)
    inst->eraseFromParent();

  return PA;
}
