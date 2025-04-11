// Copyright 2018 The Clspv Authors. All rights reserved.
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

#include <vector>

#include "llvm/IR/CallingConv.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "clspv/Option.h"

#include "ArgKind.h"
#include "InlineFuncWithSingleCallSitePass.h"

using namespace llvm;

PreservedAnalyses
clspv::InlineFuncWithSingleCallSitePass::run(Module &M,
                                             ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  if (!clspv::Option::InlineSingleCallSite())
    return PA;

  bool changed = true;
  while (changed) {
    changed = InlineFunctions(M);
  }

  // Clean up dead functions. This done here to avoid ordering requirements on
  // inlining.
  std::vector<Function *> to_delete;
  for (auto &F : M) {
    if (F.isDeclaration() || F.getCallingConv() == CallingConv::SPIR_KERNEL)
      continue;

    if (F.user_empty())
      to_delete.push_back(&F);
  }
  for (auto func : to_delete) {
    func->eraseFromParent();
  }

  return PA;
}

bool clspv::InlineFuncWithSingleCallSitePass::InlineFunctions(Module &M) {
  bool Changed = false;
  std::vector<CallInst *> to_inline;
  for (auto &F : M) {
    if (F.isDeclaration() || F.getCallingConv() == CallingConv::SPIR_KERNEL ||
        F.hasFnAttribute(Attribute::AttrKind::NoInline))
      continue;

    if (F.getNumUses() == 1) {
      if (auto *call = dyn_cast<CallInst>(*F.user_begin()))
        to_inline.push_back(call);
    }
  }

  for (auto call : to_inline) {
    InlineFunctionInfo IFI;
    // Disable generation of lifetime intrinsic.
    Changed |= InlineFunction(*call, IFI, false, nullptr, false).isSuccess();
  }

  return Changed;
}
