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

#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

#ifndef _CLSPV_LIB_REPLACE_LLVM_INTRINSICS_PASS_H
#define _CLSPV_LIB_REPLACE_LLVM_INTRINSICS_PASS_H

namespace clspv {
struct ReplaceLLVMIntrinsicsPass
    : llvm::PassInfoMixin<ReplaceLLVMIntrinsicsPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

  // TODO: update module-based funtions to work like function-based ones.
  // Except maybe lifetime intrinsics.
  bool runOnFunction(llvm::Function &F);
  bool replaceMemset(llvm::Module &M);
  bool replaceMemcpy(llvm::Module &M);
  bool removeIntrinsicDeclaration(llvm::Function &F);
  bool replaceBswap(llvm::Function &F);
  bool replaceFshr(llvm::Function &F);
  bool replaceFshl(llvm::Function &F);
  bool replaceCountZeroes(llvm::Function &F, bool leading);
  bool replaceCopysign(llvm::Function &F);
  bool replaceAddSubSat(llvm::Function &F, bool is_signed, bool is_add);

  bool replaceCallsWithValue(
      llvm::Function &F,
      std::function<llvm::Value *(llvm::CallInst *)> Replacer);

  llvm::SmallVector<llvm::Function *, 16> DeadFunctions;
};
} // namespace clspv

#endif // _CLSPV_LIB_REPLACE_LLVM_INTRINSICS_PASS_H
