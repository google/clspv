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

  for (auto &F : M) {
    if (F.getName().startswith("llvm.memcpy")) {
      SmallVector<CallInst *, 8> CallsToReplace;

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

          // Check that the pointee types match.
          assert(DstTy->getPointerElementType() ==
                 SrcTy->getPointerElementType());

          // Check that the size is a constant integer.
          assert(isa<ConstantInt>(CI->getArgOperand(2)));
          auto Size =
              dyn_cast<ConstantInt>(CI->getArgOperand(2))->getZExtValue();

          auto TypeSize = M.getDataLayout().getTypeSizeInBits(
                              DstTy->getPointerElementType()) /
                          8;

          // Check that the size is equal to the alignment of the pointee type.
          assert(Size == TypeSize);

          // Check that the alignment is a constant integer.
          assert(isa<ConstantInt>(CI->getArgOperand(3)));
          auto Alignment =
              dyn_cast<ConstantInt>(CI->getArgOperand(3))->getZExtValue();

          auto TypeAlignment = M.getDataLayout().getABITypeAlignment(
              DstTy->getPointerElementType());

          // Check that the alignment is at least the alignment of the pointee
          // type.
          assert(Alignment >= TypeAlignment);

          // Check that the alignment is a multiple of the alignment of the
          // pointee type.
          assert(0 == (Alignment % TypeAlignment));

          // Check that volatile is a constant.
          assert(isa<ConstantInt>(CI->getArgOperand(4)));

          CallsToReplace.push_back(CI);
        }
      }

      for (auto CI : CallsToReplace) {
        auto Arg0 = dyn_cast<BitCastInst>(CI->getArgOperand(0));
        auto Arg1 = dyn_cast<BitCastInst>(CI->getArgOperand(1));

        auto Dst = dyn_cast<BitCastInst>(Arg0)->getOperand(0);
        auto Src = dyn_cast<BitCastInst>(Arg1)->getOperand(0);

        auto DstTy = Dst->getType();
        auto SrcTy = Src->getType();

        auto Arg3 = dyn_cast<ConstantInt>(CI->getArgOperand(3));
        auto Arg4 = dyn_cast<ConstantInt>(CI->getArgOperand(4));

        auto I32Ty = Type::getInt32Ty(M.getContext());

        auto NewFType = FunctionType::get(F.getReturnType(),
                                          {DstTy, SrcTy, I32Ty, I32Ty}, false);

        auto SPIRVIntrinsic = "spirv.copy_memory";

        auto NewF =
            Function::Create(NewFType, F.getLinkage(), SPIRVIntrinsic, &M);

        auto NewCI = CallInst::Create(
            NewF, {Dst, Src, ConstantInt::get(I32Ty, Arg3->getZExtValue()),
                   ConstantInt::get(I32Ty, Arg4->getZExtValue())},
            "", CI);

        CI->replaceAllUsesWith(NewCI);
        CI->eraseFromParent();

        Arg0->eraseFromParent();
        Arg1->eraseFromParent();
      }
    }
  }

  return Changed;
}
