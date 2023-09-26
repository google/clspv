// Copyright 2023 The Clspv Authors. All rights reserved.
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

#ifndef _CLSPV_LIB_PRIVATE_POINTER_PHI_PASS_H
#define _CLSPV_LIB_PRIVATE_POINTER_PHI_PASS_H

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Transforms/Utils/Local.h"

#include <map>

#include "BitcastUtils.h"

namespace clspv {
struct LowerPrivatePointerPHIPass
    : llvm::PassInfoMixin<LowerPrivatePointerPHIPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  void runOnFunction(llvm::Function &F);

  using WeakInstructions = llvm::SmallVector<llvm::WeakTrackingVH, 32>;
  void cleanDeadInstructions(WeakInstructions &);
};
} // namespace clspv

#endif // _CLSPV_LIB_PRIVATE_POINTER_PHI_PASS_H
