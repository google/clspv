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

#include <unordered_map>

#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

#ifndef _CLSPV_LIB_LOGICAL_POINTER_TO_INT_PASS_H
#define _CLSPV_LIB_LOGICAL_POINTER_TO_INT_PASS_H

namespace clspv {
struct LogicalPointerToIntPass : llvm::PassInfoMixin<LogicalPointerToIntPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  bool isMemBase(llvm::Value *Val);
  bool processValue(const llvm::DataLayout &DL, llvm::Value *Value,
                    llvm::APInt &Offset, llvm::Value *&MemBase);
  uint64_t getMemBaseAddr(llvm::Value *MemBase);

  // Arbitrary initial base address for allocations. Don't use 0x0 in case of
  // problems with NULL.
  uint64_t nextBaseAddress = 0X1000000000000000;

  std::unordered_map<llvm::Value *, uint64_t> baseAddressMap;
  llvm::SmallPtrSet<llvm::Function *, 8> calledFuncs;
};
} // namespace clspv

#endif // _CLSPV_LIB_LOGICAL_POINTER_TO_INT_PASS_H
