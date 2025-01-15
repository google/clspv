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

#include "llvm/IR/Function.h"
#include "llvm/IR/PassManager.h"

#ifndef _CLSPV_LIB_FIXUP_STRUCTURED_CFG_PASS_H
#define _CLSPV_LIB_FIXUP_STRUCTURED_CFG_PASS_H

namespace clspv {
struct FixupStructuredCFGPass : llvm::PassInfoMixin<FixupStructuredCFGPass> {
  llvm::PreservedAnalyses run(llvm::Function &F,
                              llvm::FunctionAnalysisManager &FAM);

private:
  void removeUndefPHI(llvm::Function &F);
  void breakConditionalHeader(llvm::Function &F, llvm::FunctionAnalysisManager &FAM);
  void isolateContinue(llvm::Function &F, llvm::FunctionAnalysisManager &FAM);

  /**
   * Transforms a loop such as:
   *
   *  header --\
   *   /   \   |
   *  body |   |
   *    \ /    ^
   *   latch   |
   *    /  \   |
   *  exit  ---/
   *
   * Into:
   *  header  --------\
   *   /   \          |
   *  body |          |
   *    \ /           ^
   *   old_latch      |
   *    /  \          |
   *  exit new_latch -/
   *
   * When the latch contains a convergent call (e.g. a barrier). This will force
   * breakConditionalHeader to transform the loop also and effectively
   * encapsulates body within a selection now fully contained in the body of the
   * loop. This effectively moves the convergent call out of the latch where
   * SPIR-V does not guarantee reconvergence (without maximal reconvergence)
   * into a fully structured section where reconvergence is guaranteed.
   */
  void isolateConvergentLatch(llvm::Function &F, llvm::FunctionAnalysisManager &FAM);

};
} // namespace clspv

#endif // _CLSPV_LIB_FIXUP_STRUCTURED_CFG_PASS_H
