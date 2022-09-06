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

#ifndef _CLSPV_LIB_PRINTF_PASS_H
#define _CLSPV_LIB_PRINTF_PASS_H

namespace clspv {
struct PrintfPass
    : llvm::PassInfoMixin<PrintfPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);
private:
  // Find the underlying compile-time string literal, if any, for the given value
  std::string GetStringLiteral(llvm::Value *);

  // Get the printf buffer storage size for the given type
  unsigned GetPrintfStoreSize(const llvm::DataLayout &DL, llvm::Type *Ty);

  // Create a unique, argument-specififc function definition for the given call
  // to printf
  void DefinePrintfInstance(llvm::Module &, llvm::CallInst *, unsigned);
};
} // namespace clspv

#endif // _CLSPV_LIB_PRINTF_PASS_H
