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
  for (auto &U : F.uses()) {
    if (auto CI = dyn_cast<CallInst>(U.getUser())) {
      IRBuilder<> builder(CI);
      auto nan = ConstantFP::getNaN(CI->getType());
      auto zero = ConstantFP::getZero(CI->getType());
      if (auto cst = dyn_cast<ConstantFP>(CI->getOperand(0))) {
        CI->replaceAllUsesWith(ConstantFP::get(
            CI->getType(), fct(cst->getValue().convertToDouble())));
        CI->eraseFromParent();
      } else if (auto vec_cst =
                     dyn_cast<ConstantDataVector>(CI->getOperand(0))) {
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
  }
  return modified;
}
