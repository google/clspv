// Copyright 2023 The Clspv Authors. All rights reserved.
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

#include "LowerPrivatePointerPHIPass.h"
#include "BitcastUtils.h"
#include "Types.h"
#include "clspv/AddressSpace.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/IR/Instructions.h"

#define DEBUG_TYPE "LowerPrivatePointerPHI"

namespace {

using PartitionCallback = std::function<void(Instruction *)>;

/// Partition the @p Instructions based on their liveness.
void partitionInstructions(ArrayRef<WeakTrackingVH> Instructions,
                           PartitionCallback OnDead,
                           PartitionCallback OnAlive) {
  for (auto OldValueHandle : Instructions) {
    // Handle situations when the weak handle is no longer valid.
    if (!OldValueHandle.pointsToAliveValue()) {
      continue; // Nothing else to do for this handle.
    }

    auto *OldInstruction = cast<Instruction>(OldValueHandle);
    bool Dead = OldInstruction->use_empty();
    if (Dead) {
      OnDead(OldInstruction);
    } else {
      OnAlive(OldInstruction);
    }
  }
}

Value *makeNewGEP(const DataLayout &DL, IRBuilder<> &B, Instruction *Src,
                  Type *SrcTy, Type *DstTy, uint64_t CstVal, Value *DynVal,
                  size_t SmallerBitWidths) {
  auto Idxs = BitcastUtils::GetIdxsForTyFromOffset(
      DL, B, SrcTy, DstTy, CstVal, DynVal, SmallerBitWidths,
      clspv::AddressSpace::Private);
  return B.CreateGEP(SrcTy, Src, Idxs, "", true);
}

void replacePHIIncomingValue(PHINode *phi, PHINode *new_phi, Instruction *Src,
                             uint64_t CstVal, Value *DynVal) {
  IRBuilder<> B(Src);
  if (DynVal == nullptr) {
    DynVal = ConstantInt::get(new_phi->getType(), CstVal);
  } else if (CstVal != 0) {
    DynVal = B.CreateAdd(ConstantInt::get(new_phi->getType(), CstVal), DynVal);
  }
  BasicBlock *BB = nullptr;
  for (auto &incoming : phi->incoming_values()) {
    if (incoming == Src) {
      BB = phi->getIncomingBlock(incoming);
      break;
    }
  }
  assert(BB);
  new_phi->addIncoming(DynVal, BB);
  phi->removeIncomingValue(BB, false);
}

} // namespace

llvm::PreservedAnalyses
clspv::LowerPrivatePointerPHIPass::run(Module &M,
                                       llvm::ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  for (auto &F : M) {
    runOnFunction(F);
  }
  return PA;
}

void clspv::LowerPrivatePointerPHIPass::runOnFunction(Function &F) {
  auto DL = F.getParent()->getDataLayout();

  bool PrivatePointerPHI = false;
  SmallVector<AllocaInst *> worklist;
  for (auto &BB : F) {
    for (auto &I : BB) {
      if (auto alloca = dyn_cast<AllocaInst>(&I)) {
        worklist.push_back(alloca);
      } else if (auto phi = dyn_cast<PHINode>(&I)) {
        Type *Ty = phi->getType();
        if (Ty->isPointerTy() &&
            Ty->getPointerAddressSpace() == clspv::AddressSpace::Private) {
          PrivatePointerPHI = true;
        }
      }
    }
  }

  if (!PrivatePointerPHI) {
    return;
  }

  DenseSet<Value *> seen;
  WeakInstructions ToBeErased;
  DenseMap<PHINode *, PHINode *> PHIMap;
  for (auto alloca : worklist) {
    SmallVector<std::tuple<Value *, Instruction *, uint64_t, Value *>> nodes;
    for (auto use : alloca->users()) {
      nodes.push_back(std::make_tuple(use, alloca, 0, nullptr));
    }
    size_t SmallerBitWidths =
        BitcastUtils::getEleTypesBitWidths(alloca->getAllocatedType(), DL)
            .back();
    while (!nodes.empty()) {
      Value *node;
      Instruction *Src;
      uint64_t CstVal;
      Value *DynVal;
      std::tie(node, Src, CstVal, DynVal) = nodes.pop_back_val();
      if (seen.count(node) != 0) {
        if (auto phi = dyn_cast<PHINode>(node)) {
          auto new_phi = PHIMap[phi];
          assert(new_phi);
          replacePHIIncomingValue(phi, new_phi, Src, CstVal, DynVal);
        }
        continue;
      }
      if (auto gep = dyn_cast<GetElementPtrInst>(node)) {
        IRBuilder<> B(gep);
        uint64_t gep_CstVal;
        Value *gep_DynVal;
        size_t gep_SmallerBitWidths;
        BitcastUtils::ExtractOffsetFromGEP(DL, B, gep, gep_CstVal, gep_DynVal,
                                           gep_SmallerBitWidths);
        if (SmallerBitWidths > gep_SmallerBitWidths) {
          llvm_unreachable("should not be possible to have a smallerbitwidths "
                           "smaller than smallest bitwidth of src alloca");
        } else if (gep_SmallerBitWidths > SmallerBitWidths) {
          size_t coef = gep_SmallerBitWidths / SmallerBitWidths;
          gep_CstVal *= coef;
          if (gep_DynVal != nullptr) {
            gep_DynVal = BitcastUtils::CreateMul(B, coef, gep_DynVal);
          }
        }
        CstVal += gep_CstVal;
        if (DynVal == nullptr) {
          DynVal = gep_DynVal;
        } else if (gep_DynVal != nullptr) {
          DynVal = B.CreateAdd(DynVal, gep_DynVal);
        }
        ToBeErased.push_back(gep);
        for (auto use : gep->users()) {
          nodes.push_back(std::make_tuple(use, gep, CstVal, DynVal));
        }
      } else if (auto phi = dyn_cast<PHINode>(node)) {
        IRBuilder<> B(phi);
        Type *intTy = clspv::PointersAre64Bit(*(F.getParent()))
                          ? B.getInt64Ty()
                          : B.getInt32Ty();

        auto new_phi = B.CreatePHI(intTy, phi->getNumIncomingValues());
        replacePHIIncomingValue(phi, new_phi, Src, CstVal, DynVal);
        PHIMap[phi] = new_phi;
        ToBeErased.push_back(phi);
        for (auto &incoming : phi->incoming_values()) {
          if (isa<UndefValue>(incoming)) {
            new_phi->addIncoming(UndefValue::get(intTy),
                                 phi->getIncomingBlock(incoming));
          }
        }
        for (auto use : phi->users()) {
          nodes.push_back(std::make_tuple(use, phi, 0, new_phi));
        }
      } else if (auto load = dyn_cast<LoadInst>(node)) {
        IRBuilder<> B(load);
        auto gep =
            makeNewGEP(DL, B, alloca, alloca->getAllocatedType(),
                       load->getType(), CstVal, DynVal, SmallerBitWidths);
        auto new_load = B.CreateLoad(load->getType(), gep);
        load->replaceAllUsesWith(new_load);
        ToBeErased.push_back(load);
      } else if (auto store = dyn_cast<StoreInst>(node)) {
        IRBuilder<> B(store);
        auto gep =
            makeNewGEP(DL, B, alloca, alloca->getAllocatedType(),
                       store->getType(), CstVal, DynVal, SmallerBitWidths);
        B.CreateStore(store->getValueOperand(), gep);
        ToBeErased.push_back(store);
      } else if (auto ptrtoint = dyn_cast<PtrToIntInst>(node)) {
        IRBuilder<> B(ptrtoint);
        auto gep = makeNewGEP(DL, B, alloca, alloca->getAllocatedType(),
                              B.getIntNTy(SmallerBitWidths), CstVal, DynVal,
                              SmallerBitWidths);
        auto newPtrToInt = B.CreatePtrToInt(gep, ptrtoint->getDestTy());
        ptrtoint->replaceAllUsesWith(newPtrToInt);
        ToBeErased.push_back(ptrtoint);
      } else {
        llvm_unreachable("Unexpected node when traversing alloca users");
      }
      seen.insert(node);
    }
  }

  cleanDeadInstructions(ToBeErased);
}

void clspv::LowerPrivatePointerPHIPass::cleanDeadInstructions(
    WeakInstructions &OldInstructions) {
  // Collect all instructions that have been replaced by another one, and remove
  // them from the function. To address dependencies, use a fixed-point
  // algorithm:
  //  1. Collect the instructions that have been replaced.
  //  2. Collect among these instructions the ones which have no uses and remove
  //     them.
  //  3. Repeat step 2 until no progress is made.

  // Select instructions that were replaced by another one.
  // Ignore constants as they are not owned by the module and therefore don't
  // need to be removed.
  for (bool Progress = true; Progress;) {
    std::size_t PreviousSize = OldInstructions.size();

    // Identify instructions that are actually dead and can be removed using
    // RecursivelyDeleteTriviallyDeadInstructions.
    // Use a third buffer to capture the instructions that are still alive to
    // avoid mutating OldInstructions while iterating over it.
    WeakInstructions NextBatch;
    WeakInstructions TriviallyDeads;
    partitionInstructions(
        OldInstructions,
        [&TriviallyDeads](Instruction *DeadInstruction) {
          // Additionally, manually remove from the parent instructions with
          // possible side-effect, generally speaking, such as call or alloca
          // instructions. Those are not trivially dead.
          if (isInstructionTriviallyDead(DeadInstruction)) {
            TriviallyDeads.push_back(DeadInstruction);
          } else {
            DeadInstruction->eraseFromParent();
          }
        },
        [&NextBatch](Instruction *AliveInstruction) {
          NextBatch.push_back(AliveInstruction);
        });

    RecursivelyDeleteTriviallyDeadInstructions(TriviallyDeads);

    // Update OldInstructions for the next iteration of the fixed-point.
    OldInstructions = std::move(NextBatch);
    Progress = (OldInstructions.size() < PreviousSize);
  }

#ifndef NDEBUG
  if (!OldInstructions.empty()) {
    dbgs() << "These values were expected to be removed:\n";
    for (auto ValueHandle : OldInstructions) {
      dbgs() << '\t' << *ValueHandle << '\n';
    }
    llvm_unreachable("Not all supposedly-dead instruction were removed!");
  }
#endif
}
