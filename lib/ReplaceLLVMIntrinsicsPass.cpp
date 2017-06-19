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

#include <llvm/IR/Constants.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/Module.h>
#include <llvm/Pass.h>
#include <llvm/Support/raw_ostream.h>
#include <llvm/Transforms/Utils/Cloning.h>

#include <spirv/1.0/spirv.hpp>

using namespace llvm;

#define DEBUG_TYPE "ReplaceLLVMIntrinsics"

namespace {
struct ReplaceLLVMIntrinsicsPass final : public ModulePass {
  static char ID;
  ReplaceLLVMIntrinsicsPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;
  bool replaceMemset(Module &M);
  bool replaceMemcpy(Module &M);
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

  Changed |= replaceMemset(M);
  Changed |= replaceMemcpy(M);

  return Changed;
}

bool ReplaceLLVMIntrinsicsPass::replaceMemset(Module &M) {
  bool Changed = false;

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

        if (auto Bitcast = dyn_cast<BitCastInst>(NewArg)) {
          NewArg = Bitcast->getOperand(0);
        }

        auto Ty = NewArg->getType();
        auto PointeeTy = Ty->getPointerElementType();

        auto NewFType =
            FunctionType::get(F.getReturnType(), {Ty, PointeeTy}, false);

        // Create our fake intrinsic to initialize it to 0.
        auto SPIRVIntrinsic = "spirv.store_null";

        auto NewF =
            Function::Create(NewFType, F.getLinkage(), SPIRVIntrinsic, &M);

        auto Zero = Constant::getNullValue(PointeeTy);

        auto NewCI = CallInst::Create(NewF, {NewArg, Zero}, "", CI);

        CI->replaceAllUsesWith(NewCI);
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
  auto match_types = [&Layout](CallInst &CI, Type **DstElemTy, Type **SrcElemTy,
                               unsigned *NumDstUnpackings,
                               unsigned *NumSrcUnpackings) {
    unsigned *numSrcUnpackings = 0;
    unsigned *numDstUnpackings = 0;
    while (*SrcElemTy != *DstElemTy) {
      auto SrcElemSize = Layout.getTypeSizeInBits(*SrcElemTy);
      auto DstElemSize = Layout.getTypeSizeInBits(*DstElemTy);
      if (SrcElemSize >= DstElemSize) {
        assert((*SrcElemTy)->isArrayTy());
        *SrcElemTy = (*SrcElemTy)->getArrayElementType();
        (*NumSrcUnpackings)++;
      } else if (DstElemSize >= SrcElemSize) {
        assert((*DstElemTy)->isArrayTy());
        *DstElemTy = (*DstElemTy)->getArrayElementType();
        (*NumDstUnpackings)++;
      } else {
        errs() << "Don't know how to unpack types for memcpy: " << CI
               << "\ngot to: " << **DstElemTy << " vs " << **SrcElemTy << "\n";
        assert(false && "Don't know how to unpack these types");
      }
    }
  };

  for (auto &F : M) {
    if (F.getName().startswith("llvm.memcpy")) {
      SmallPtrSet<Instruction *, 8> BitCastsToForget;
      SmallVector<CallInst *, 8> CallsToReplaceWithSpirvCopyMemory;

      for (auto U : F.users()) {
        if (auto CI = dyn_cast<CallInst>(U)) {
          assert(isa<BitCastInst>(CI->getArgOperand(0)));
          auto Dst = dyn_cast<BitCastInst>(CI->getArgOperand(0))->getOperand(0);

          assert(isa<BitCastInst>(CI->getArgOperand(1)));
          auto Src = dyn_cast<BitCastInst>(CI->getArgOperand(1))->getOperand(0);

          // The original type of Dst we get from the argument to the bitcast
          // instruction.
          auto DstTy = Dst->getType();
          assert(DstTy->isPointerTy());

          // The original type of Src we get from the argument to the bitcast
          // instruction.
          auto SrcTy = Src->getType();
          assert(SrcTy->isPointerTy());

          auto DstElemTy = DstTy->getPointerElementType();
          auto SrcElemTy = SrcTy->getPointerElementType();
          unsigned NumDstUnpackings = 0;
          unsigned NumSrcUnpackings = 0;
          match_types(*CI, &DstElemTy, &SrcElemTy, &NumDstUnpackings,
                      &NumSrcUnpackings);

          // Check that the pointee types match.
          assert(DstElemTy == SrcElemTy);

          // Check that the size is a constant integer.
          assert(isa<ConstantInt>(CI->getArgOperand(2)));
          auto Size =
              dyn_cast<ConstantInt>(CI->getArgOperand(2))->getZExtValue();

          auto DstElemSize = Layout.getTypeSizeInBits(DstElemTy) / 8;

          // Check that the size is a multiple of the size of the pointee type.
          assert(Size % DstElemSize == 0);

          // Check that the alignment is a constant integer.
          assert(isa<ConstantInt>(CI->getArgOperand(3)));
          auto Alignment =
              dyn_cast<ConstantInt>(CI->getArgOperand(3))->getZExtValue();

          auto TypeAlignment = Layout.getABITypeAlignment(DstElemTy);

          // Check that the alignment is at least the alignment of the pointee
          // type.
          assert(Alignment >= TypeAlignment);

          // Check that the alignment is a multiple of the alignment of the
          // pointee type.
          assert(0 == (Alignment % TypeAlignment));

          // Check that volatile is a constant.
          assert(isa<ConstantInt>(CI->getArgOperand(4)));

          CallsToReplaceWithSpirvCopyMemory.push_back(CI);
        }
      }

      for (auto CI : CallsToReplaceWithSpirvCopyMemory) {
        auto Arg0 = dyn_cast<BitCastInst>(CI->getArgOperand(0));
        auto Arg1 = dyn_cast<BitCastInst>(CI->getArgOperand(1));
        auto Arg3 = dyn_cast<ConstantInt>(CI->getArgOperand(3));
        auto Arg4 = dyn_cast<ConstantInt>(CI->getArgOperand(4));

        auto I32Ty = Type::getInt32Ty(M.getContext());
        auto Alignment = ConstantInt::get(I32Ty, Arg3->getZExtValue());
        auto Volatile = ConstantInt::get(I32Ty, Arg4->getZExtValue());

        auto Dst = dyn_cast<BitCastInst>(Arg0)->getOperand(0);
        auto Src = dyn_cast<BitCastInst>(Arg1)->getOperand(0);

        auto DstElemTy = Dst->getType()->getPointerElementType();
        auto SrcElemTy = Src->getType()->getPointerElementType();
        unsigned NumDstUnpackings = 0;
        unsigned NumSrcUnpackings = 0;
        match_types(*CI, &DstElemTy, &SrcElemTy, &NumDstUnpackings,
                    &NumSrcUnpackings);

        assert(NumDstUnpackings < 2 && "Need to generalize dst unpacking case");
        assert(NumSrcUnpackings < 2 && "Need to generalize src unpacking case");
        assert((NumDstUnpackings == 0 || NumSrcUnpackings == 0) &&
               "Need to generalize unpackings in both dimensions");

        auto SPIRVIntrinsic = "spirv.copy_memory";

        auto Size = dyn_cast<ConstantInt>(CI->getArgOperand(2))->getZExtValue();

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

            auto SrcElemPtr = Builder.CreateGEP(Src, SrcIndices);
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
        BitCastsToForget.insert(Arg0);
        BitCastsToForget.insert(Arg1);
      }
      for (auto* Inst : BitCastsToForget) {
        Inst->eraseFromParent();
      }
    }
  }

  return Changed;
}
