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
#include "llvm/Transforms/Utils/Cloning.h"

#include "clspv/AddressSpace.h"
#include "clspv/Option.h"

#include "BitcastUtils.h"
#include "Types.h"

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
uint64_t MaxAllocSize = 0x0000100000000000;

static bool IsTargetAddrSpace(unsigned AS) {
  return AS == clspv::AddressSpace::Private ||
         AS == clspv::AddressSpace::Local ||
         !clspv::Option::PhysicalStorageBuffers();
}

static bool FunctionShouldBeInlined(Function &F) {
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      if (isa<IntToPtrInst>(I) || isa<PtrToIntInst>(I)) {
        return true;
      }
    }
  }
  return false;
}

bool clspv::LogicalPointerToIntPass::InlineFunctions(Module &M) {
  bool Changed = false;
  std::vector<CallInst *> to_inline;
  for (auto &F : M) {
    if (F.isDeclaration() || F.getCallingConv() == CallingConv::SPIR_KERNEL)
      continue;

    if (!FunctionShouldBeInlined(F)) {
      continue;
    }

    for (auto user : F.users()) {
      if (auto call = dyn_cast<CallInst>(user))
        to_inline.push_back(call);
    }
  }

  for (auto call : to_inline) {
    InlineFunctionInfo IFI;
    Changed |= InlineFunction(*call, IFI, false, nullptr, false).isSuccess();
  }
  return Changed;
}

PreservedAnalyses
clspv::LogicalPointerToIntPass::run(Module &M, ModuleAnalysisManager &MAM) {
  PreservedAnalyses PA;

  if (!clspv::PointersAre64Bit(M)) {
    nextBaseAddress = 0x10000000ULL;
    MaxAllocSize = 0x10000000ULL;
  }

  while (InlineFunctions(M)) {
  }

  SmallVector<Instruction *, 8> InstrsToProcess;
  SmallVector<ICmpInst *, 8> PointerICmpToProcess;
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
        } else if (auto ICmp = dyn_cast<ICmpInst>(&I)) {
          if (auto *PtrTy =
                  dyn_cast<PointerType>(ICmp->getOperand(0)->getType())) {
            if (IsTargetAddrSpace(PtrTy->getAddressSpace())) {
              PointerICmpToProcess.push_back(ICmp);
            }
          }
        }
      }
    }
  }

  for (auto *ICmp : PointerICmpToProcess) {
    IntegerType *SizeT = clspv::PointersAre64Bit(M)
                             ? IntegerType::get(M.getContext(), 64)
                             : IntegerType::get(M.getContext(), 32);
    IRBuilder<> B(ICmp);
    auto LHS = B.CreatePtrToInt(ICmp->getOperand(0), SizeT);
    if (auto *Cast = dyn_cast<CastInst>(LHS)) {
      InstrsToProcess.push_back(Cast);
    }
    auto RHS = B.CreatePtrToInt(ICmp->getOperand(1), SizeT);
    if (auto *Cast = dyn_cast<CastInst>(RHS)) {
      InstrsToProcess.push_back(Cast);
    }
    ICmp->replaceAllUsesWith(B.CreateICmp(ICmp->getPredicate(), LHS, RHS));
  }

  for (auto *Instr : InstrsToProcess) {
    auto *IntTy = cast<IntegerType>(Instr->getType());

    auto *PtrOp = Instr->getOperand(0);
    Value *MemBase = nullptr;
    uint64_t CstOffset = 0;
    Value *DynOffset = nullptr;

    if (processValue(M.getDataLayout(), PtrOp, CstOffset, DynOffset, MemBase)) {
      auto BaseAddr = getMemBaseAddr(MemBase);
      Value *Replacement;
      Replacement = ConstantInt::get(IntTy, BaseAddr + CstOffset);
      if (DynOffset != nullptr) {
        IRBuilder<> B(Instr);
        Replacement = B.CreateAdd(Replacement, DynOffset);
      }
      Instr->replaceAllUsesWith(Replacement);
    }
  }

  return PA;
}

bool clspv::LogicalPointerToIntPass::processValue(const DataLayout &DL,
                                                  Value *Val,
                                                  uint64_t &CstOffset,
                                                  llvm::Value *&DynOffset,
                                                  Value *&MemBase) {
  if (auto *GEP = dyn_cast<GetElementPtrInst>(Val)) {
    // Convert GEP indices to byte offset
    IRBuilder<> B(GEP);
    size_t SmallerBitWidths;
    uint64_t CstVal = 0;
    Value *DynVal = nullptr;
    BitcastUtils::ExtractOffsetFromGEP(DL, B, GEP, CstVal, DynVal,
                                       SmallerBitWidths);
    CstOffset += CstVal * SmallerBitWidths / CHAR_BIT;
    if (DynVal) {
      DynVal = BitcastUtils::CreateMul(B, SmallerBitWidths / CHAR_BIT, DynVal);
    }
    if (DynOffset && DynVal) {
      DynOffset = B.CreateAdd(DynOffset, DynVal);
    } else if (DynVal) {
      DynOffset = DynVal;
    }
    return processValue(DL, GEP->getPointerOperand(), CstOffset, DynOffset,
                        MemBase);
  } else if (auto *Bitcast = dyn_cast<BitCastInst>(Val)) {
    return processValue(DL, Bitcast->getOperand(0), CstOffset, DynOffset,
                        MemBase);
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
        Arg->getType()->isPointerTy() &&
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
