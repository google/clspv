// Copyright 2022 The Clspv Authors. All rights reserved.
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

#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"

#include "clspv/AddressSpace.h"

#include "BitcastUtils.h"

#include "LogicalPointerToIntPass.h"

using namespace llvm;

// Support limited uses of PtrToInt on logical address spaces, in particular
// uses where a pointer is converted to an integer but not used to form an
// integer which is converted back to a pointer.
//
// This is safe to do because:
// * Private and local addresses are meaningless on the host, and cannot be
//   dereferenced by any subsequent kernels.
// * The actual numeric ranges of the address spaces may overlap, so we do not
//   need to consider the physical address range of global and constant memory.
//
// The primary use of this limited functionality is to inspect the memory layout
// of struct types.

// Arbitrary 'large enough' size. We have a 64-bit range to use and in practice
// the amount of private and local memory will be quite small.
constexpr uint64_t MaxAllocSize = 0x0000100000000000;

bool IsTargetAddrSpace(unsigned AS) {
  return AS == clspv::AddressSpace::Private || AS == clspv::AddressSpace::Local;
}

PreservedAnalyses
clspv::LogicalPointerToIntPass::run(Module &M, ModuleAnalysisManager &MAM) {
  PreservedAnalyses PA;

  // If a kernel is called from another function, local pointer arguments
  // cannot be guaranteed to the 'base' address of the allocation, track these
  // kernels so we can skip them if needed
  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        if (auto *Call = dyn_cast<CallInst>(&I)) {
          if (auto *CalledFunc = Call->getCalledFunction()) {
            calledFuncs.insert(CalledFunc);
          }
        }
      }
    }
  }

  SmallVector<Instruction *, 8> InstrsToProcess;
  for (auto &F : M) {
    BitcastUtils::RemoveCstExprFromFunction(&F);

    for (auto &BB : F) {
      for (auto &I : BB) {
        if (auto *Cast = dyn_cast<CastInst>(&I)) {
          if (Cast->getOpcode() == Instruction::PtrToInt) {
            if (auto *PtrTy =
                    cast<PointerType>(Cast->getOperand(0)->getType())) {
              if (IsTargetAddrSpace(PtrTy->getAddressSpace())) {
                InstrsToProcess.push_back(Cast);
              }
            }
          } else if (Cast->getOpcode() == Instruction::IntToPtr) {
            if (auto *PtrTy = cast<PointerType>(Cast->getType())) {
              if (IsTargetAddrSpace(PtrTy->getAddressSpace())) {
                // Bail out if we see a relevant IntToPtr anywhere, as it means
                // we cannot guarantee a generated address won't be dereferenced
                return PA;
              }
            }
          }
        }
      }
    }
  }

  for (auto *Instr : InstrsToProcess) {
    auto *IntTy = cast<IntegerType>(Instr->getType());

    auto *PtrOp = Instr->getOperand(0);
    APInt Offset(M.getDataLayout().getPointerSizeInBits(
                     PtrOp->getType()->getPointerAddressSpace()),
                 0);
    Value *MemBase = nullptr;

    if (processValue(M.getDataLayout(), PtrOp, Offset, MemBase)) {
      auto BaseAddr = getMemBaseAddr(MemBase);
      auto *Replacement =
          ConstantInt::get(IntTy, BaseAddr + Offset.getZExtValue());
      Instr->replaceAllUsesWith(Replacement);
    }
  }

  return PA;
}

bool clspv::LogicalPointerToIntPass::processValue(const DataLayout &DL,
                                                  Value *Val, APInt &Offset,
                                                  Value *&MemBase) {
  if (auto *GEP = dyn_cast<GetElementPtrInst>(Val)) {
    // Convert GEP indices to byte offset
    if (GEP->hasAllConstantIndices() && isMemBase(GEP->getPointerOperand())) {
      if (GEP->accumulateConstantOffset(DL, Offset)) {
        MemBase = GEP->getPointerOperand();
        return true;
      }
    }
  } else if (auto *Bitcast = dyn_cast<BitCastInst>(Val)) {
    return processValue(DL, Bitcast->getOperand(0), Offset, MemBase);
  } else if (isMemBase(Val)) {
    MemBase = Val;
    return true;
  }

  return false;
}

bool clspv::LogicalPointerToIntPass::isMemBase(Value *Val) {
  if (isa<AllocaInst>(Val)) {
    return true;
  } else if (auto *Arg = dyn_cast<Argument>(Val)) {
    auto *F = Arg->getParent();
    // Local memory args are only allowed in actual kernels, pointers passed
    // to regular functions might not be the base of the actual allocation
    if (F->getCallingConv() == llvm::CallingConv::SPIR_KERNEL &&
        !calledFuncs.contains(F) && Arg->getType()->isPointerTy() &&
        IsTargetAddrSpace(Arg->getType()->getPointerAddressSpace())) {
      return true;
    }
  } else if (auto *GV = dyn_cast<GlobalVariable>(Val)) {
    if (IsTargetAddrSpace(GV->getAddressSpace())) {
      return true;
    }
  }

  return false;
}

uint64_t clspv::LogicalPointerToIntPass::getMemBaseAddr(llvm::Value *MemBase) {
  auto InsertInfo = baseAddressMap.insert({MemBase, nextBaseAddress});
  if (InsertInfo.second) {
    nextBaseAddress += MaxAllocSize;
  }
  return InsertInfo.first->second;
}
