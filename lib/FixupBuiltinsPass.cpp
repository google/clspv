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

#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"

#include "Builtins.h"
#include "FixupBuiltinsPass.h"
#include "Types.h"

#include "clspv/Option.h"

#include <cmath>

using namespace clspv;
using namespace llvm;

namespace {
double rsqrt(double input) { return 1.0 / sqrt(input); }
} // namespace

PreservedAnalyses FixupBuiltinsPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  for (auto &F : M) {
    runOnFunction(F);
  }
  return PA;
}

bool FixupBuiltinsPass::runOnFunction(Function &F) {
  auto &FI = Builtins::Lookup(&F);
  switch (FI.getType()) {
  case Builtins::kSqrt:
    return fixupSqrt(F, sqrt);
  case Builtins::kRsqrt:
    return fixupSqrt(F, rsqrt);
  case Builtins::kReadImagef:
  case Builtins::kReadImagei:
  case Builtins::kReadImageui:
    if (clspv::Option::HackImage1dBufferBGRA() &&
        !FI.getParameter(1).isSampler()) {
      return fixupReadImage(F);
    } else {
      return false;
    }
  default:
    return false;
  }
}

bool FixupBuiltinsPass::fixupSqrt(Function &F, double (*fct)(double)) {
  // We only want to perform this transformation on the native sqrt/rsqrt
  // implementation.
  if (!F.isDeclaration()) {
    return false;
  }
  bool modified = false;
  SmallVector<CallInst *> worklist;
  for (auto &U : F.uses()) {
    if (auto CI = dyn_cast<CallInst>(U.getUser())) {
      worklist.push_back(CI);
    }
  }
  for (auto CI : worklist) {
    IRBuilder<> builder(CI);
    auto nan = ConstantFP::getNaN(CI->getType());
    auto zero = ConstantFP::getZero(CI->getType());
    if (auto cst = dyn_cast<ConstantFP>(CI->getOperand(0))) {
      CI->replaceAllUsesWith(ConstantFP::get(
          CI->getType(), fct(cst->getValue().convertToDouble())));
      CI->eraseFromParent();
    } else if (auto vec_cst = dyn_cast<ConstantDataVector>(CI->getOperand(0))) {
      Value *Res = UndefValue::get(vec_cst->getType());
      for (unsigned int i = 0; i < vec_cst->getNumElements(); i++) {
        auto fp = cast<ConstantFP>(vec_cst->getElementAsConstant(i))
                      ->getValue()
                      .convertToDouble();
        Res = builder.CreateInsertElement(
            Res, ConstantFP::get(CI->getType()->getScalarType(), fct(fp)), i);
      }
      CI->replaceAllUsesWith(Res);
    } else {
      auto op_is_positive = builder.CreateFCmpOGE(CI->getOperand(0), zero);
      builder.SetInsertPoint(CI->getNextNode());
      SelectInst *select =
          cast<SelectInst>(builder.CreateSelect(op_is_positive, zero, nan));
      CI->replaceAllUsesWith(select);
      select->setTrueValue(CI);
    }
    modified = true;
  }
  return modified;
}

bool FixupBuiltinsPass::fixupReadImage(Function &F) {
  const uint32_t CL_BGRA = 0x10B6;
  DenseMap<Value *, Type *> cache;
  bool changed = false;
  for (auto &U : F.uses()) {
    if (auto CI = dyn_cast<CallInst>(U.getUser())) {
      auto Img = CI->getOperand(0);
      auto *image_ty = InferType(Img, F.getContext(), &cache);
      if (clspv::ImageDimensionality(image_ty) == spv::DimBuffer) {
        IRBuilder<> B(CI->getInsertionPointAfterDef());

        auto shuffle =
            cast<ShuffleVectorInst>(B.CreateShuffleVector(CI, {2, 1, 0, 3}));
        auto channel_order_fct = F.getParent()->getOrInsertFunction(
            "_Z23get_image_channel_order21ocl_image1d_buffer_ro",
            FunctionType::get(B.getInt32Ty(), {image_ty}, false));
        auto channel_order = B.CreateCall(channel_order_fct, {Img});
        auto cmp = B.CreateICmpNE(channel_order, B.getInt32(CL_BGRA));
        SelectInst *select = cast<SelectInst>(B.CreateSelect(cmp, CI, shuffle));

        // Do not use tmp before because llvm can optimize the node and not
        // create it. But we need to use tmp to be able to replace all uses of
        // CI without having a circular dependency.
        auto tmp = UndefValue::get(CI->getType());
        select->setTrueValue(tmp);
        shuffle->setOperand(0, tmp);

        CI->replaceAllUsesWith(select);

        // Put the right argument at the proper places.
        select->setTrueValue(CI);
        shuffle->setOperand(0, CI);
        changed = true;
      }
    }
  }
  return changed;
}
