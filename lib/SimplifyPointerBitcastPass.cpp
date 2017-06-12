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

#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/Module.h>
#include <llvm/Pass.h>

using namespace llvm;

#define DEBUG_TYPE "SimplifyPointerBitcast"

namespace {
struct SimplifyPointerBitcastPass : public ModulePass {
  static char ID;
  SimplifyPointerBitcastPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;

  bool runOnBitcastFromBitcast(Module &M) const;
  bool runOnBitcastFromGEP(Module &M) const;
  bool runOnGEPFromGEP(Module &M) const;
};
}

char SimplifyPointerBitcastPass::ID = 0;
static RegisterPass<SimplifyPointerBitcastPass>
    X("SimplifyPointerBitcast", "Simplify Pointer Bitcast Pass");

namespace clspv {
llvm::ModulePass *createSimplifyPointerBitcastPass() {
  return new SimplifyPointerBitcastPass();
}
}

bool SimplifyPointerBitcastPass::runOnModule(Module &M) {
  bool Changed = false;

  // Loop through our individual simplification passes until they stop changing
  // things.
  for (bool localChanged = true; localChanged; Changed |= localChanged) {
    localChanged = false;

    localChanged |= runOnBitcastFromGEP(M);
    localChanged |= runOnBitcastFromBitcast(M);
    localChanged |= runOnGEPFromGEP(M);
  }

  return Changed;
}

bool SimplifyPointerBitcastPass::runOnBitcastFromGEP(Module &M) const {
  SmallVector<BitCastInst *, 16> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // If we have a bitcast instruction...
        if (auto Bitcast = dyn_cast<BitCastInst>(&I)) {
          // ... whose source is a GEP instruction...
          if (auto GEP = dyn_cast<GetElementPtrInst>(Bitcast->getOperand(0))) {
            // ... where the GEP is retrieving an element of the same type...
            if (GEP->getSourceElementType() == GEP->getResultElementType()) {
              auto GEPTy = GEP->getResultElementType();
              auto BitcastTy = Bitcast->getType()->getPointerElementType();
              // ... and the types have a known compile time size...
              if ((0 != GEPTy->getPrimitiveSizeInBits()) &&
                  (0 != BitcastTy->getPrimitiveSizeInBits())) {
                // ... record the bitcast as something we need to process.
                WorkList.push_back(Bitcast);
              }
            }
          }
        }
      }
    }
  }

  const bool Changed = !WorkList.empty();

  for (auto Bitcast : WorkList) {
    auto BitcastTy = Bitcast->getType();
    auto BitcastElementTy = BitcastTy->getPointerElementType();

    auto GEP = cast<GetElementPtrInst>(Bitcast->getOperand(0));

    auto SrcTySize = GEP->getResultElementType()->getPrimitiveSizeInBits();
    auto DstTySize = BitcastElementTy->getPrimitiveSizeInBits();

    SmallVector<Value *, 4> GEPArgs(GEP->idx_begin(), GEP->idx_end());

    // If the source type is smaller than the destination type...
    if (SrcTySize < DstTySize) {
      // ... we need to divide the last index of the GEP by the size difference.
      auto LastIndex = GEPArgs.back();
      GEPArgs.back() = BinaryOperator::Create(
          Instruction::SDiv, LastIndex,
          ConstantInt::get(LastIndex->getType(), DstTySize / SrcTySize), "",
          Bitcast);
    } else if (SrcTySize > DstTySize) {
      // ... we need to multiply the last index of the GEP by the size
      // difference.
      auto LastIndex = GEPArgs.back();
      GEPArgs.back() = BinaryOperator::Create(
          Instruction::Mul, LastIndex,
          ConstantInt::get(LastIndex->getType(), SrcTySize / DstTySize), "",
          Bitcast);
    } else {
      // ... the arguments are the same size, nothing to do!
    }

    // Create a new bitcast from the GEP argument to the bitcast type.
    auto NewBitcast = CastInst::CreatePointerCast(GEP->getPointerOperand(),
                                                  BitcastTy, "", Bitcast);

    // Create a new GEP from the (maybe modified) GEPArgs.
    auto NewGEP = GetElementPtrInst::Create(BitcastElementTy, NewBitcast,
                                            GEPArgs, "", Bitcast);

    // And replace the original bitcast with our replacement GEP.
    Bitcast->replaceAllUsesWith(NewGEP);

    // Remove the bitcast as it has no users now.
    Bitcast->eraseFromParent();

    // Check if the old GEP had no other users...
    if (0 == GEP->getNumUses()) {
      // ... and remove it if we were its only user.
      GEP->eraseFromParent();
    }
  }

  return Changed;
}

bool SimplifyPointerBitcastPass::runOnBitcastFromBitcast(Module &M) const {
  SmallVector<BitCastInst *, 16> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // If we have a bitcast instruction...
        if (auto Bitcast = dyn_cast<BitCastInst>(&I)) {
          // ... whose source is a bitcast instruction...
          if (isa<BitCastInst>(Bitcast->getOperand(0))) {
            // ... record the bitcast as something we need to process.
            WorkList.push_back(Bitcast);
          }
        }
      }
    }
  }

  const bool Changed = !WorkList.empty();

  for (auto Bitcast : WorkList) {
    auto OtherBitcast = cast<BitCastInst>(Bitcast->getOperand(0));

    // Create a new bitcast from the other bitcasts argument to our type.
    auto NewBitcast = CastInst::CreatePointerCast(
        OtherBitcast->getOperand(0), Bitcast->getType(), "", Bitcast);

    // And replace the original bitcast with our replacement bitcast.
    Bitcast->replaceAllUsesWith(NewBitcast);

    // Remove the bitcast as it has no users now.
    Bitcast->eraseFromParent();

    // Check if the other bitcast had no other users...
    if (0 == OtherBitcast->getNumUses()) {
      // ... and remove it if we were its only user.
      OtherBitcast->eraseFromParent();
    }
  }

  return Changed;
}

bool SimplifyPointerBitcastPass::runOnGEPFromGEP(Module &M) const {
  SmallVector<GetElementPtrInst *, 16> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // If we have a GEP instruction...
        if (auto GEP = dyn_cast<GetElementPtrInst>(&I)) {
          // ... whose operand is also a GEP instruction...
          if (isa<GetElementPtrInst>(GEP->getPointerOperand())) {
            // ... record the GEP as something we need to process.
            WorkList.push_back(GEP);
          }
        }
      }
    }
  }

  const bool Changed = !WorkList.empty();

  for (GetElementPtrInst *GEP : WorkList) {
    IRBuilder<> Builder(GEP);

    auto OtherGEP = cast<GetElementPtrInst>(GEP->getPointerOperand());

    SmallVector<Value *, 8> Idxs;

    Value *SrcLastIdxOp = OtherGEP->getOperand(OtherGEP->getNumOperands() - 1);
    Value *GEPIdxOp = GEP->getOperand(1);
    Value *MergedIdx = Builder.CreateAdd(SrcLastIdxOp, GEPIdxOp);

    Idxs.append(OtherGEP->op_begin() + 1, OtherGEP->op_end() - 1);
    Idxs.push_back(MergedIdx);
    Idxs.append(GEP->op_begin() + 2, GEP->op_end());

    Value *NewGEP = nullptr;
    if (GEP->isInBounds() && OtherGEP->isInBounds()) {
      NewGEP = Builder.CreateInBoundsGEP(OtherGEP->getPointerOperand(), Idxs);
    } else {
      NewGEP = Builder.CreateGEP(OtherGEP->getPointerOperand(), Idxs);
    }

    // And replace the original GEP with our replacement GEP.
    GEP->replaceAllUsesWith(NewGEP);

    // Remove the GEP as it has no users now.
    GEP->eraseFromParent();

    // Check if the other GEP had no other users...
    if (0 == OtherGEP->getNumUses()) {
      // ... and remove it if we were its only user.
      OtherGEP->eraseFromParent();
    }
  }

  return Changed;
}
