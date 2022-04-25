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

#include "ArgKind.h"

#ifndef _CLSPV_LIB_AUTO_POD_ARGS_PASS_H
#define _CLSPV_LIB_AUTO_POD_ARGS_PASS_H

namespace clspv {
struct AutoPodArgsPass : llvm::PassInfoMixin<AutoPodArgsPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  // Decides the pod args implementation for each kernel individually.
  void runOnFunction(llvm::Function &F);

  // Makes all kernels use |impl| for pod args.
  void AnnotateAllKernels(llvm::Module &M, clspv::PodArgImpl impl);

  // Makes kernel |F| use |impl| as the pod arg implementation.
  void AddMetadata(llvm::Function &F, clspv::PodArgImpl impl);

  // Returns true if |type| contains an array. Does not look through pointers
  // since we are dealing with pod args.
  bool ContainsArrayType(llvm::Type *type) const;

  // Returns true if |type| contains a |width|-bit integer or floating-point
  // type. Does not look through pointer since we are dealing with pod args.
  bool ContainsSizedType(llvm::Type *type, uint32_t width) const;
};
} // namespace clspv

#endif // _CLSPV_LIB_AUTO_POD_ARGS_PASS_H
