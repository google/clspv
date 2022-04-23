// Copyright 2020-2021 The Clspv Authors. All rights reserved.
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

#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/LoopPass.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Pass.h"
#include "llvm/Support/Debug.h"
#include "llvm/Transforms/Utils/Local.h"

#include "clspv/Passes.h"
#include "Passes.h"

using namespace llvm;

#define DEBUG_TYPE "GEPLoopVariable"

namespace {
/// This pass will gather Pointer PHIs on a loop,
/// where those pointers are incremented inside the loop.
/// Because the SPIRVProducer will use the 1st element of the GEP
/// to figure out whether to generate a spv::OpPtrAccessChain or
/// a spv::OpAccessChain, we cannot have chained-GEPs.
/// LLVM will simplify a sequence of GEPs during CFG simplification,
/// but where loops are involved, we must do so manually.
class GEPLoopVariable final
    : public LoopPass {
public:
  GEPLoopVariable() : LoopPass(ID) {}

  bool runOnLoop(Loop *L, LPPassManager &LPM) override;
  StringRef getPassName() const override { return "Simplify GEP as Loop Variable"; }

  static char ID;
};

bool ReplacePHINode(Loop *L, PHINode *Node) {
  const unsigned NumValues = Node->getNumIncomingValues();
  SmallVector<Value *, 16> Offsets;
  Offsets.reserve(NumValues);
  Value *SourcePointer = nullptr;
  Type *OffsetType = nullptr;

  LLVM_DEBUG(dbgs() << "Finding incoming pointers for " << *Node << '\n');

  for (unsigned i = 0; i < NumValues; ++i) {
    auto *Value = Node->getIncomingValue(i);
    auto *Block = Node->getIncomingBlock(i);
    if (L->contains(Block)) {
      if (Node == Value) {
        if (!OffsetType)
          // Guess at 32-bit offsets.
          OffsetType = IntegerType::get(Node->getContext(), 32);
        // Self-reference; increment is 0.
        Offsets.push_back(ConstantInt::get(OffsetType, 0, false));
        LLVM_DEBUG(dbgs() << " * " << *Value << " -> offset 0\n");
      } else if (auto *GEP = dyn_cast<GetElementPtrInst>(Value)) {
        // This is an incremented pointer. Figure out by how much.
        // If this isn't a self-reference increment, then skip.
        if (GEP->getPointerOperand() != Node)
          return false;
        if (GEP->getNumIndices() != 1)
          return false;
        Offsets.push_back(*GEP->idx_begin());
        if (!OffsetType)
          OffsetType = Offsets.back()->getType();
        LLVM_DEBUG(dbgs() << " * " << *Value << " -> offset " << *Offsets.back() << '\n');
      } else {
        return false;
      }
    } else {
      // This is a loop-incoming value.
      Offsets.push_back(nullptr);
      if (!SourcePointer)
        SourcePointer = Value;
      else if (SourcePointer != Value)
        // Multiple incoming pointers; can't handle.
        return false;
    }
  }

  assert(SourcePointer && "No Loop-incoming pointer");

  // This would imply that the PHINode is loop-invariant,
  // and should be hoisted.
  assert(OffsetType && "No Loop-dependent offsets found");

  // Ensure that all offset types match.
  for (auto *Offset : Offsets) {
    if (!Offset)
      continue;

    assert(OffsetType == Offset->getType() && "Typecasting required");
  }

  auto *Header = Node->getParent();
  PHINode *NewNode = PHINode::Create(OffsetType, NumValues, "LoopGEPOffset", Node);

  LLVM_DEBUG(dbgs() << " Imported offsets: " << *NewNode <<'\n');

  // Ensure we don't create sequences of GEPs.
  LLVM_DEBUG(dbgs() << " Source pointer: " << *SourcePointer << '\n');
  SmallVector<Value *, 16> NewGepIndices;
  while (auto *GEP = dyn_cast<GetElementPtrInst>(SourcePointer)) {
    LLVM_DEBUG(dbgs() << " Importing gep indices: " << *SourcePointer << '\n');
    NewGepIndices.insert(NewGepIndices.begin(),
                         GEP->indices().begin(), GEP->indices().end());
    SourcePointer = GEP->getPointerOperand();
  }

  Value *TrailIndex;
  if (NewGepIndices.empty())
    TrailIndex = ConstantInt::get(OffsetType, 0, false);
  else
    TrailIndex = NewGepIndices.pop_back_val();
  LLVM_DEBUG(dbgs() << " PHI incoming offset: " << *TrailIndex << '\n');

  assert(NumValues == Offsets.size());
  // Build a PHINode with incoming offsets.
  for (unsigned i = 0; i < NumValues; ++i) {
    Value *Offset = Offsets[i];
    auto *Block = Node->getIncomingBlock(i);

    if (!Offset) {
      NewNode->addIncoming(TrailIndex, Block);
      continue;
    }

    auto *I = cast<Instruction>(Node->getIncomingValue(i));

    auto *Add = BinaryOperator::CreateAdd(NewNode, Offset, "LoopGEPInc", I);
    NewNode->addIncoming(Add, Block);
    LLVM_DEBUG(dbgs() << " Incoming offset: " << *Add << " from " << *I <<'\n');
    // We need to remove the instruction so that a RAUW later works correctly.
    assert(isa<GetElementPtrInst>(I));
    assert(I->getOperand(0) == Node);
    I->replaceAllUsesWith(UndefValue::get(I->getType()));
    I->eraseFromParent();
  }

  // Now the PHI needs to be replaced with a GEP using the accumulated offset.
  NewGepIndices.push_back(NewNode);
  auto *InsertPoint = &*Header->getFirstInsertionPt();
  auto *PointeeTy = SourcePointer->getType()->getPointerElementType();
  auto *GEP = GetElementPtrInst::Create(PointeeTy, SourcePointer, NewGepIndices, "LoopGEPReplacement", InsertPoint);
  LLVM_DEBUG(dbgs() << " PHI replaced with " << *GEP << '\n');
  Node->replaceAllUsesWith(GEP);
  RecursivelyDeleteDeadPHINode(Node);

  return true;
}
} // anon namespace

char GEPLoopVariable::ID = 0;

bool GEPLoopVariable::runOnLoop(Loop *L, LPPassManager &LPM) {
  // Search for any pointers incremented in the loop.
  // This is done by finding PHINodes on the header.
  auto *Header = L->getHeader();
  assert(Header && "Loop has no header");

  SmallVector<PHINode *, 4> Pointers;
  for (auto &I : Header->getInstList()) {
    if (auto *PHI = dyn_cast<PHINode>(&I)) {
      if (PHI->getType()->isPointerTy() && PHI->getType()->getPointerAddressSpace() == 0)
        Pointers.push_back(PHI);
    } else {
      // PHINodes must be at the start of the block.
      // If this isn't a PHINode, we're done.
      break;
    }
  }

  if (Pointers.empty())
    return false;

  bool Modified = false;
  for (auto *Node : Pointers)
    Modified |= ReplacePHINode(L, Node);

  return Modified;
}


INITIALIZE_PASS(GEPLoopVariable, "GepLoopVar",
                "Simplify GEP as Loop Variable", false, false)

llvm::Pass *clspv::createGEPVarPass() {
  return new GEPLoopVariable();
}
