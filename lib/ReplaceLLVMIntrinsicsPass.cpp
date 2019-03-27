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
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "spirv/1.0/spirv.hpp"

using namespace llvm;

#define DEBUG_TYPE "ReplaceLLVMIntrinsics"

namespace {
struct ReplaceLLVMIntrinsicsPass final : public ModulePass {
  static char ID;
  ReplaceLLVMIntrinsicsPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;
  bool replaceMemset(Module &M);
  bool replaceMemcpy(Module &M);
  bool removeLifetimeDeclarations(Module &M);
};
}

char ReplaceLLVMIntrinsicsPass::ID = 0;
static RegisterPass<ReplaceLLVMIntrinsicsPass>
    X("ReplaceLLVMIntrinsics", "Replace LLVM intrinsics Pass");

namespace clspv {
ModulePass *createReplaceLLVMIntrinsicsPass() {
  return new ReplaceLLVMIntrinsicsPass();
}
}

bool ReplaceLLVMIntrinsicsPass::runOnModule(Module &M) {
  bool Changed = false;

  // Remove lifetime annotations first.  They coulud be using memset
  // and memcpy calls.
  Changed |= removeLifetimeDeclarations(M);
  Changed |= replaceMemset(M);
  Changed |= replaceMemcpy(M);

  return Changed;
}

bool ReplaceLLVMIntrinsicsPass::replaceMemset(Module &M) {
  bool Changed = false;
  auto Layout = M.getDataLayout();

  for (auto &F : M) {
    if (F.getName().startswith("llvm.memset")) {
      SmallVector<CallInst *, 8> CallsToReplace;

      for (auto U : F.users()) {
        if (auto CI = dyn_cast<CallInst>(U)) {
          auto Initializer = dyn_cast<ConstantInt>(CI->getArgOperand(1));

          // We only handle cases where the initializer is a constant int that
          // is 0.
          if (!Initializer || (0 != Initializer->getZExtValue())) {
            Initializer->print(errs());
            llvm_unreachable("Unhandled llvm.memset.* instruction that had a "
                             "non-0 initializer!");
          }

          CallsToReplace.push_back(CI);
        }
      }

      for (auto CI : CallsToReplace) {
        auto NewArg = CI->getArgOperand(0);

        if (auto Bitcast = dyn_cast<BitCastOperator>(NewArg)) {
          NewArg = Bitcast->getOperand(0);
        }

        auto NumBytes = cast<ConstantInt>(CI->getArgOperand(2))->getZExtValue();

        auto Ty = NewArg->getType();
        auto PointeeTy = Ty->getPointerElementType();

        auto NewFType =
            FunctionType::get(F.getReturnType(), {Ty, PointeeTy}, false);

        // Create our fake intrinsic to initialize it to 0.
        auto SPIRVIntrinsic = "spirv.store_null";

        auto NewF =
            Function::Create(NewFType, F.getLinkage(), SPIRVIntrinsic, &M);

        auto Zero = Constant::getNullValue(PointeeTy);

        const auto num_stores = NumBytes / Layout.getTypeAllocSize(PointeeTy);
        assert((NumBytes == num_stores * Layout.getTypeAllocSize(PointeeTy)) &&
               "Null memset can't be divided evenly across multiple stores.");
        assert((num_stores & 0xFFFFFFFF) == num_stores);

        // Generate the first store.
        CallInst::Create(NewF, {NewArg, Zero}, "", CI);

        // Generate subsequent stores, but only if needed.
        if (num_stores) {
          auto I32Ty = Type::getInt32Ty(M.getContext());
          auto One = ConstantInt::get(I32Ty, 1);
          auto Ptr = NewArg;
          for (uint32_t i = 1; i < num_stores; i++) {
            Ptr = GetElementPtrInst::Create(PointeeTy, Ptr, {One}, "", CI);
            CallInst::Create(NewF, {Ptr, Zero}, "", CI);
          }
        }

        CI->eraseFromParent();

        if (auto Bitcast = dyn_cast<BitCastInst>(NewArg)) {
          Bitcast->eraseFromParent();
        }
      }
    }
  }

  return Changed;
}

bool ReplaceLLVMIntrinsicsPass::replaceMemcpy(Module &M) {
  bool Changed = false;
  auto Layout = M.getDataLayout();

  // Unpack source and destination types until we find a matching
  // element type.  Count the number of levels we unpack for the
  // source and destination types.  So far this only works for
  // array types, but could be generalized to other regular types
  // like vectors.
  auto match_types = [&Layout](CallInst &CI, uint64_t Size, Type **DstElemTy,
                               Type **SrcElemTy, unsigned *NumDstUnpackings,
                               unsigned *NumSrcUnpackings) {
    auto descend_type = [](Type *InType) {
      Type *OutType = InType;
      if (OutType->isStructTy()) {
        OutType = OutType->getStructElementType(0);
      } else if (OutType->isArrayTy()) {
        OutType = OutType->getArrayElementType();
      } else if (OutType->isVectorTy()) {
        OutType = OutType->getVectorElementType();
      } else {
        assert(false && "Don't know how to descend into type");
      }

      return OutType;
    };

    unsigned *numSrcUnpackings = 0;
    unsigned *numDstUnpackings = 0;
    while (*SrcElemTy != *DstElemTy) {
      auto SrcElemSize = Layout.getTypeSizeInBits(*SrcElemTy);
      auto DstElemSize = Layout.getTypeSizeInBits(*DstElemTy);
      if (SrcElemSize >= DstElemSize) {
        *SrcElemTy = descend_type(*SrcElemTy);
        (*NumSrcUnpackings)++;
      } else if (DstElemSize >= SrcElemSize) {
        *DstElemTy = descend_type(*DstElemTy);
        (*NumDstUnpackings)++;
      } else {
        errs() << "Don't know how to unpack types for memcpy: " << CI
               << "\ngot to: " << **DstElemTy << " vs " << **SrcElemTy << "\n";
        assert(false && "Don't know how to unpack these types");
      }
    }

    auto DstElemSize = Layout.getTypeSizeInBits(*DstElemTy) / 8;
    while (Size < DstElemSize) {
      *DstElemTy = descend_type(*DstElemTy);
      *SrcElemTy = descend_type(*SrcElemTy);
      (*NumDstUnpackings)++;
      (*NumSrcUnpackings)++;
      DstElemSize = Layout.getTypeSizeInBits(*DstElemTy) / 8;
    }
  };

  for (auto &F : M) {
    if (F.getName().startswith("llvm.memcpy")) {
      SmallPtrSet<Instruction *, 8> BitCastsToForget;
      SmallVector<CallInst *, 8> CallsToReplaceWithSpirvCopyMemory;

      for (auto U : F.users()) {
        if (auto CI = dyn_cast<CallInst>(U)) {
          assert(isa<BitCastOperator>(CI->getArgOperand(0)));
          auto Dst = dyn_cast<BitCastOperator>(CI->getArgOperand(0))->getOperand(0);

          assert(isa<BitCastOperator>(CI->getArgOperand(1)));
          auto Src = dyn_cast<BitCastOperator>(CI->getArgOperand(1))->getOperand(0);

          // The original type of Dst we get from the argument to the bitcast
          // instruction.
          auto DstTy = Dst->getType();
          assert(DstTy->isPointerTy());

          // The original type of Src we get from the argument to the bitcast
          // instruction.
          auto SrcTy = Src->getType();
          assert(SrcTy->isPointerTy());

          // Check that the size is a constant integer.
          assert(isa<ConstantInt>(CI->getArgOperand(2)));
          auto Size =
              dyn_cast<ConstantInt>(CI->getArgOperand(2))->getZExtValue();

          auto DstElemTy = DstTy->getPointerElementType();
          auto SrcElemTy = SrcTy->getPointerElementType();
          unsigned NumDstUnpackings = 0;
          unsigned NumSrcUnpackings = 0;
          match_types(*CI, Size, &DstElemTy, &SrcElemTy, &NumDstUnpackings,
                      &NumSrcUnpackings);

          // Check that the pointee types match.
          assert(DstElemTy == SrcElemTy);

          auto DstElemSize = Layout.getTypeSizeInBits(DstElemTy) / 8;

          // Check that the size is a multiple of the size of the pointee type.
          assert(Size % DstElemSize == 0);

          // Check that the alignment is a constant integer.
          assert(isa<ConstantInt>(CI->getArgOperand(3)));
          auto Alignment = cast<MemIntrinsic>(CI)->getDestAlignment();

          auto TypeAlignment = Layout.getABITypeAlignment(DstElemTy);

          // Check that the alignment is at least the alignment of the pointee
          // type.
          assert(Alignment >= TypeAlignment);

          // Check that the alignment is a multiple of the alignment of the
          // pointee type.
          assert(0 == (Alignment % TypeAlignment));

          // Check that volatile is a constant.
          assert(isa<ConstantInt>(CI->getArgOperand(3)));

          CallsToReplaceWithSpirvCopyMemory.push_back(CI);
        }
      }

      for (auto CI : CallsToReplaceWithSpirvCopyMemory) {
        auto Arg0 = dyn_cast<BitCastOperator>(CI->getArgOperand(0));
        auto Arg1 = dyn_cast<BitCastOperator>(CI->getArgOperand(1));
        auto Arg3 = dyn_cast<ConstantInt>(CI->getArgOperand(3));

        auto I32Ty = Type::getInt32Ty(M.getContext());
        auto Alignment = ConstantInt::get(I32Ty, cast<MemIntrinsic>(CI)->getDestAlignment());
        auto Volatile = ConstantInt::get(I32Ty, Arg3->getZExtValue());

        auto Dst = Arg0->getOperand(0);
        auto Src = Arg1->getOperand(0);

        auto DstElemTy = Dst->getType()->getPointerElementType();
        auto SrcElemTy = Src->getType()->getPointerElementType();
        unsigned NumDstUnpackings = 0;
        unsigned NumSrcUnpackings = 0;
        auto Size = dyn_cast<ConstantInt>(CI->getArgOperand(2))->getZExtValue();
        match_types(*CI, Size, &DstElemTy, &SrcElemTy, &NumDstUnpackings,
                    &NumSrcUnpackings);
        auto SPIRVIntrinsic = "spirv.copy_memory";

        auto DstElemSize = Layout.getTypeSizeInBits(DstElemTy) / 8;

        IRBuilder<> Builder(CI);

        if (NumSrcUnpackings == 0 && NumDstUnpackings == 0) {
          auto NewFType = FunctionType::get(
              F.getReturnType(), {Dst->getType(), Src->getType(), I32Ty, I32Ty},
              false);
          auto NewF =
              Function::Create(NewFType, F.getLinkage(), SPIRVIntrinsic, &M);
          Builder.CreateCall(NewF, {Dst, Src, Alignment, Volatile}, "");
        } else {
          auto Zero = ConstantInt::get(I32Ty, 0);
          SmallVector<Value *, 3> SrcIndices;
          SmallVector<Value *, 3> DstIndices;
          // Make unpacking indices.
          for (unsigned unpacking = 0; unpacking < NumSrcUnpackings;
               ++unpacking) {
            SrcIndices.push_back(Zero);
          }
          for (unsigned unpacking = 0; unpacking < NumDstUnpackings;
               ++unpacking) {
            DstIndices.push_back(Zero);
          }
          // Add a placeholder for the final index.
          SrcIndices.push_back(Zero);
          DstIndices.push_back(Zero);

          // Build the function and function type only once.
          FunctionType* NewFType = nullptr;
          Function* NewF = nullptr;

          IRBuilder<> Builder(CI);
          for (unsigned i = 0; i < Size / DstElemSize; ++i) {
            auto Index = ConstantInt::get(I32Ty, i);
            SrcIndices.back() = Index;
            DstIndices.back() = Index;

            // Avoid the builder for Src in order to prevent the folder from
            // creating constant expressions for constant memcpys.
            auto SrcElemPtr =
                GetElementPtrInst::CreateInBounds(Src, SrcIndices, "", CI);
            auto DstElemPtr = Builder.CreateGEP(Dst, DstIndices);
            NewFType =
                NewFType != nullptr
                    ? NewFType
                    : FunctionType::get(F.getReturnType(),
                                        {DstElemPtr->getType(),
                                         SrcElemPtr->getType(), I32Ty, I32Ty},
                                        false);
            NewF = NewF != nullptr ? NewF
                                   : Function::Create(NewFType, F.getLinkage(),
                                                      SPIRVIntrinsic, &M);
            Builder.CreateCall(
                NewF, {DstElemPtr, SrcElemPtr, Alignment, Volatile}, "");
          }
        }

        // Erase the call.
        CI->eraseFromParent();

        // Erase the bitcasts.  A particular bitcast might be used
        // in more than one memcpy, so defer actual deleting until later.
        if (isa<BitCastInst>(Arg0))
          BitCastsToForget.insert(dyn_cast<BitCastInst>(Arg0));
        if (isa<BitCastInst>(Arg1))
          BitCastsToForget.insert(dyn_cast<BitCastInst>(Arg1));
      }
      for (auto* Inst : BitCastsToForget) {
        Inst->eraseFromParent();
      }
    }
  }

  return Changed;
}

bool ReplaceLLVMIntrinsicsPass::removeLifetimeDeclarations(Module &M) {
  // SPIR-V OpLifetimeStart and OpLifetimeEnd require Kernel capability.
  // Vulkan doesn't support that, so remove all lifteime bounds declarations.

  bool Changed = false;

  SmallVector<Function *, 2> WorkList;
  for (auto &F : M) {
    if (F.getName().startswith("llvm.lifetime.")) {
      WorkList.push_back(&F);
    }
  }

  for (auto *F : WorkList) {
    Changed = true;
    // Copy users to avoid modifying the list in place.
    SmallVector<User *, 8> users(F->users());
    for (auto U : users) {
      if (auto *CI = dyn_cast<CallInst>(U)) {
        CI->eraseFromParent();
      }
    }
    F->eraseFromParent();
  }

  return Changed;
}
