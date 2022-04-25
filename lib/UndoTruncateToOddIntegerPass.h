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

#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

#ifndef _CLSPV_LIB_UNDO_TRUNCATE_TO_ODD_INTEGER_PASS_H
#define _CLSPV_LIB_UNDO_TRUNCATE_TO_ODD_INTEGER_PASS_H

namespace clspv {
struct UndoTruncateToOddIntegerPass
    : llvm::PassInfoMixin<UndoTruncateToOddIntegerPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  // Maps a value to its zero-extended value.  This is the memoization table for
  // ZeroExtend.
  llvm::DenseMap<llvm::Value *, llvm::Value *> extended_value_;

  // Returns a 32-bit zero-extended version of the given argument.
  // Candidates for erasure are added to |zombies_|, before their feeding
  // values are created.
  // TODO(dneto): Handle 64 bit case as well, but separately.
  llvm::Value *ZeroExtend(llvm::Value *v, uint32_t desired_bit_width);

  // The list of things that might be dead.
  llvm::UniqueVector<llvm::Instruction *> zombies_;
};
} // namespace clspv

#endif // _CLSPV_LIB_UNDO_TRUNCATE_TO_ODD_INTEGER_PASS_H
