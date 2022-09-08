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

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"

#include "Builtins.h"
#include "FixupBuiltinsPass.h"

using namespace clspv;
using namespace llvm;

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
  case Builtins::kRsqrt:
    return fixupSqrt(F);
  default:
    return false;
  }
}

bool FixupBuiltinsPass::fixupSqrt(Function &F) {
  // We only want to perform this transformation if no sqrt/rsqrt
  // implementation has been linked.
  if (!F.isDeclaration()) {
    return false;
  }
  bool modified = false;
  for (auto &U : F.uses()) {
    if (auto CI = dyn_cast<CallInst>(U.getUser())) {
      IRBuilder<> builder(CI);
      auto nan = ConstantFP::getNaN(CI->getType());
      auto zero = ConstantFP::getZero(CI->getType());
      auto op_is_positive = builder.CreateFCmpOGE(CI->getOperand(0), zero);
      builder.SetInsertPoint(CI->getNextNode());
      SelectInst *select =
          cast<SelectInst>(builder.CreateSelect(op_is_positive, zero, nan));
      CI->replaceAllUsesWith(select);
      select->setTrueValue(CI);
      modified = true;
    }
  }
  return modified;
}
