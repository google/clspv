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

#ifndef _CLSPV_LIB_SCALARIZE_PASS_H
#define _CLSPV_LIB_SCALARIZE_PASS_H

namespace clspv {
struct ScalarizePass : llvm::PassInfoMixin<ScalarizePass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  // Breaks a struct type phi down into its constituent elements. It does this
  // recursively in the event the subtypes are also structs. Returns the
  // replacement value. Returns the replacment value for the phi.
  llvm::Value *ScalarizePhi(llvm::PHINode *phi);

  // Phi nodes that need to be deleted.
  std::vector<llvm::PHINode *> to_delete_;
};
} // namespace clspv

#endif // _CLSPV_LIB_SCALARIZE_PASS_H
