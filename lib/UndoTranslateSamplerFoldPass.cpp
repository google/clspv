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
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "Constants.h"
#include "UndoTranslateSamplerFoldPass.h"

using namespace llvm;

#define DEBUG_TYPE "UndoTranslateSamplerFold"

PreservedAnalyses
clspv::UndoTranslateSamplerFoldPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  auto F = M.getFunction(clspv::TranslateSamplerInitializerFunction());

  if (!F) {
    return PA;
  }

  SmallVector<CallInst *, 1> BadCalls;

  for (auto U : F->users()) {
    if (auto CI = dyn_cast<CallInst>(U)) {
      // Get the single argument to the translate sampler function.
      auto Arg = CI->getArgOperand(0);

      if (isa<ConstantInt>(Arg)) {
        continue;
      } else if (isa<SelectInst>(Arg)) {
        BadCalls.push_back(CI);
      } else {
        Arg->print(errs());
        std::string msg = "Unhandled argument to ";
        msg += clspv::TranslateSamplerInitializerFunction();
        llvm_unreachable(msg.c_str());
      }
    }
  }

  if (0 == BadCalls.size()) {
    return PA;
  }

  for (auto CI : BadCalls) {
    // Get the single argument to the translate sampler function.
    auto Arg = CI->getArgOperand(0);

    if (auto Sel = dyn_cast<SelectInst>(Arg)) {
      auto NewTrue = CallInst::Create(
          CI->getCalledFunction(), Sel->getTrueValue(), "", CI->getIterator());
      auto NewFalse = CallInst::Create(
          CI->getCalledFunction(), Sel->getFalseValue(), "", CI->getIterator());
      auto NewSel = SelectInst::Create(Sel->getCondition(), NewTrue, NewFalse,
                                       "", CI->getIterator());

      CI->replaceAllUsesWith(NewSel);
      CI->eraseFromParent();
      Sel->eraseFromParent();
    }
  }

  return PA;
}
