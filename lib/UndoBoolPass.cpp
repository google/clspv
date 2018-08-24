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

#define DEBUG_TYPE "undobool"

namespace {
struct UndoBoolPass : public ModulePass {
  static char ID;
  UndoBoolPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;
};
}

char UndoBoolPass::ID = 0;
static RegisterPass<UndoBoolPass> X("UndoBool", "Undo Bool Pass");

namespace clspv {
ModulePass *createUndoBoolPass() { return new UndoBoolPass(); }
}

bool UndoBoolPass::runOnModule(Module &M) {
  bool Changed = false;

  SmallVector<Instruction *, 8> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        switch (I.getOpcode()) {
        default:
          // Skip this instruction as it did not match
          continue;
        case Instruction::ZExt:
          // We are looking for an instruction that produces an i8 from an i1.
          if (I.getOperand(0)->getType()->isIntegerTy(1) &&
              I.getType()->isIntegerTy(8)) {
            WorkList.push_back(&I);
          }
          break;
        }
      }
    }
  }

  for (Instruction *I : WorkList) {
    SmallVector<Instruction *, 1> ToReplace;

    // Walk the users of the instruction looking for a trunc
    for (User *U : I->users()) {
      if (Instruction *OI = dyn_cast<Instruction>(U)) {
        // We are looking for a trunc instruction that produces an i1 from i8.
        if ((Instruction::Trunc == OI->getOpcode()) &&
            OI->getOperand(0)->getType()->isIntegerTy(8) &&
            OI->getType()->isIntegerTy(1)) {
          ToReplace.push_back(OI);
        }
      }
    }

    for (Instruction *OI : ToReplace) {
      OI->replaceAllUsesWith(I->getOperand(0));
      OI->eraseFromParent();
    }

    I->eraseFromParent();
  }

  return Changed;
}
