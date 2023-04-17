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

#include "LowerAddrSpaceCastPass.h"
#include "BitcastUtils.h"
#include "Types.h"
#include "clspv/AddressSpace.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Transforms/Utils/Local.h"

using namespace llvm;

#define DEBUG_TYPE "LowerAddrSpaceCast"

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

bool isGenericPTy(Type *Ty) {
  return Ty && Ty->isPointerTy() &&
         Ty->getPointerAddressSpace() == clspv::AddressSpace::Generic;
}
} // namespace

PreservedAnalyses clspv::LowerAddrSpaceCastPass::run(Module &M,
                                                     ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  for (auto &F : M.functions()) {
    BitcastUtils::RemoveCstExprFromFunction(&F);
    runOnFunction(F);
  }

  return PA;
}

Value *clspv::LowerAddrSpaceCastPass::visit(Value *V) {
  auto it = ValueMap.find(V);
  if (it != ValueMap.end()) {
    return it->second;
  }
  auto *I = dyn_cast<Instruction>(V);
  if (I == nullptr) {
    return V;
  }

  if (auto *alloca = dyn_cast<AllocaInst>(I)) {
    if (alloca->getAllocatedType()->isPointerTy() &&
        alloca->getAllocatedType()->getPointerAddressSpace() !=
            clspv::AddressSpace::Private) {
      return visit(alloca);
    }
  }

  if (isGenericPTy(I->getType())) {
    return visit(I);
  }

  for (auto &Operand : I->operands()) {
    if (isGenericPTy(Operand->getType())) {
      return visit(I);
    }
  }

  return V;
}

llvm::Value *
clspv::LowerAddrSpaceCastPass::visitAllocaInst(llvm::AllocaInst &I) {
  IRBuilder<> B(&I);
  auto alloca = B.CreateAlloca(
      PointerType::get(I.getContext(), clspv::AddressSpace::Private),
      I.getArraySize(), I.getName());
  registerReplacement(&I, alloca);
  return alloca;
}

llvm::Value *clspv::LowerAddrSpaceCastPass::visitLoadInst(llvm::LoadInst &I) {
  IRBuilder<> B(&I);
  Type *Ty = I.getType();
  Value *Ptr = visit(I.getPointerOperand());
  if (isGenericPTy(Ty)) {
    Ty = clspv::InferType(Ptr, I.getContext(), &TypeCache);
  }
  auto load = B.CreateLoad(Ty, Ptr, I.getName());
  registerReplacement(&I, load);
  if (!isGenericPTy(I.getType())) {
    I.replaceAllUsesWith(load);
  }
  return load;
}

llvm::Value *clspv::LowerAddrSpaceCastPass::visitStoreInst(llvm::StoreInst &I) {
  IRBuilder<> B(&I);
  Value *Val = visit(I.getValueOperand());
  Value *Ptr = visit(I.getPointerOperand());
  if (isa<ConstantPointerNull>(Val)) {
    Val = ConstantPointerNull::get(PointerType::get(
        I.getContext(), clspv::InferType(Ptr, I.getContext(), &TypeCache)
                            ->getPointerAddressSpace()));
  }
  auto store = B.CreateStore(Val, Ptr);
  registerReplacement(&I, store);
  return store;
}

llvm::Value *clspv::LowerAddrSpaceCastPass::visitGetElementPtrInst(
    llvm::GetElementPtrInst &I) {
  IRBuilder<> B(&I);
  auto gep = B.CreateGEP(I.getSourceElementType(), visit(I.getPointerOperand()),
                         SmallVector<Value *>{I.indices()}, I.getName(),
                         I.isInBounds());
  registerReplacement(&I, gep);
  return gep;
}

llvm::Value *clspv::LowerAddrSpaceCastPass::visitAddrSpaceCastInst(
    llvm::AddrSpaceCastInst &I) {
  auto ptr = visit(I.getPointerOperand());
  // Returns a pointer that points to a region in the address space if
  // "to_addrspace" can cast ptr to the address space. Otherwise it returns
  // NULL.
  if (ptr->getType() != I.getSrcTy() && ptr->getType() != I.getDestTy()) {
    ptr = ConstantPointerNull::get(cast<PointerType>(I.getType()));
    I.replaceAllUsesWith(ptr);
  }
  registerReplacement(&I, ptr);
  return ptr;
}

llvm::Value *clspv::LowerAddrSpaceCastPass::visitICmpInst(llvm::ICmpInst &I) {
  IRBuilder<> B(&I);
  Value *Op0 = visit(I.getOperand(0));
  Value *Op1 = visit(I.getOperand(1));
  if (Op0->getType() != Op1->getType()) {
    if (isa<ConstantPointerNull>(Op0)) {
      Op0 = ConstantPointerNull::get(cast<PointerType>(Op1->getType()));
    } else if (isa<ConstantPointerNull>(Op1)) {
      Op1 = ConstantPointerNull::get(cast<PointerType>(Op0->getType()));
    } else {
      llvm_unreachable("unsupported operand of icmp in loweraddrspacecast");
    }
  }

  auto icmp = B.CreateICmp(I.getPredicate(), Op0, Op1, I.getName());
  registerReplacement(&I, icmp);
  I.replaceAllUsesWith(icmp);
  return icmp;
}

Value *clspv::LowerAddrSpaceCastPass::visitInstruction(Instruction &I) {
#ifndef NDEBUG
  dbgs() << "Instruction not handled: " << I << '\n';
#endif
  llvm_unreachable("Missing support for instruction");
}

void clspv::LowerAddrSpaceCastPass::registerReplacement(Value *U, Value *V) {
  LLVM_DEBUG(dbgs() << "Replacement for " << *U << ": " << *V << '\n');
  assert(ValueMap.count(U) == 0 && "Value already registered");
  ValueMap.insert({U, V});
}

void clspv::LowerAddrSpaceCastPass::runOnFunction(Function &F) {
  LLVM_DEBUG(dbgs() << "Processing " << F.getName() << '\n');

  // Skip declarations.
  if (F.isDeclaration()) {
    return;
  }
  for (Instruction &I : instructions(&F)) {
    // Use the Value overload of visit to ensure cache is used.
    visit(static_cast<Value *>(&I));
  }

  cleanDeadInstructions();

  LLVM_DEBUG(dbgs() << "Final version for " << F.getName() << '\n');
  LLVM_DEBUG(dbgs() << F << '\n');
}

void clspv::LowerAddrSpaceCastPass::cleanDeadInstructions() {
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
  using WeakInstructions = SmallVector<WeakTrackingVH, 32>;
  WeakInstructions OldInstructions;
  for (const auto &Mapping : ValueMap) {
    if (Mapping.getSecond() != nullptr) {
      if (auto *OldInstruction = dyn_cast<Instruction>(Mapping.getFirst())) {
        OldInstructions.push_back(OldInstruction);
      } else {
        assert(isa<Constant>(Mapping.getFirst()) &&
               "Only Instruction and Constant are expected in ValueMap");
      }
    }
  }

  // Erase any mapping, as they won't be valid anymore.
  ValueMap.clear();

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
