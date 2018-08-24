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

#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

using namespace llvm;

#define DEBUG_TYPE "UndoTruncatedSwitchCondition"

namespace {
struct UndoTruncatedSwitchConditionPass : public ModulePass {
  static char ID;
  UndoTruncatedSwitchConditionPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;
};
}

char UndoTruncatedSwitchConditionPass::ID = 0;
static RegisterPass<UndoTruncatedSwitchConditionPass>
    X("UndoTruncatedSwitchCondition", "Undo Truncated Switch Condition Pass");

namespace clspv {
ModulePass *createUndoTruncatedSwitchConditionPass() {
  return new UndoTruncatedSwitchConditionPass();
}
}

bool UndoTruncatedSwitchConditionPass::runOnModule(Module &M) {
  bool Changed = false;

  SmallVector<SwitchInst *, 8> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // If we have a switch instruction.
        if (auto SI = dyn_cast<SwitchInst>(&I)) {
          // Whose condition is a strangely sized integer type.
          switch (SI->getCondition()->getType()->getIntegerBitWidth()) {
          default:
            WorkList.push_back(SI);
          case 8:
          case 16:
          case 32:
          case 64:
            break;
          }
        }
      }
    }
  }

  for (auto SI : WorkList) {
    auto Cond = SI->getCondition();

    if (auto TI = dyn_cast<TruncInst>(Cond)) {
      auto Op = TI->getOperand(0);
      SI->setCondition(Op);

      auto OpTy = Op->getType();

      for (auto Cases : SI->cases()) {
        // The original value of the case.
        auto V = Cases.getCaseValue()->getZExtValue();

        // A new value for the case with the correct type.
        auto CI = dyn_cast<ConstantInt>(ConstantInt::get(OpTy, V));

        // And we replace the old value.
        Cases.setValue(CI);
      }

      TI->eraseFromParent();
    } else {
      Cond->print(errs());
      llvm_unreachable("Unhandled switch instruction condition!");
    }
  }

  return Changed;
}
