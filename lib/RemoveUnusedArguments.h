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

#ifndef _CLSPV_LIB_REMOVE_UNUSED_ARGUMENTS_PASS_H
#define _CLSPV_LIB_REMOVE_UNUSED_ARGUMENTS_PASS_H

namespace clspv {
struct RemoveUnusedArguments : llvm::PassInfoMixin<RemoveUnusedArguments> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  struct Candidate {
    llvm::Function *function;
    llvm::SmallVector<llvm::Value *, 8> args;
  };

  // Populate |candidates| with non-kernel functions that have unused function
  // parameters. Returns true if any such functions are found.
  bool findCandidates(llvm::Module &M, std::vector<Candidate> *candidates);

  // Remove unused parameters in |candidates|. Rebuilds the functions without
  // the unused parameters. Updates calls and metadata to use the new function.
  void removeUnusedParameters(llvm::Module &M,
                              const std::vector<Candidate> &candidates);
};
} // namespace clspv

#endif // _CLSPV_LIB_REMOVE_UNUSED_ARGUMENTS_PASS_H
