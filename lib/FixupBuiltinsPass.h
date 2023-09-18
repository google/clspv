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

#ifndef _CLSPV_LIB_BUILTIN_FIXUP_PASS_H
#define _CLSPV_LIB_BUILTIN_FIXUP_PASS_H

namespace clspv {
// This pass performs transformations on calls to builtin functions without
// erasing them from the module.
struct FixupBuiltinsPass : llvm::PassInfoMixin<FixupBuiltinsPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  bool runOnFunction(llvm::Function &F);

  // If this detects builtin calls that will generate calls to the Sqrt or
  // InverseSqrt glsl instructions it adds checks to guarantee the result is a
  // NaN if the input is negative.
  bool fixupSqrt(llvm::Function &F, double (*fct)(double));

  // Shuffle the component of a read_image of a image1d_buffer if the image
  // order is CL_BGRA.
  bool fixupReadImage(llvm::Function &F);
};
} // namespace clspv

#endif // _CLSPV_LIB_BUILTIN_FIXUP_PASS_H
