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

#include <utility>

#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

#include "Builtins.h"

#ifndef _CLSPV_LIB_SPECIALIZE_IMAGE_TYPES_PASS_H
#define _CLSPV_LIB_SPECIALIZE_IMAGE_TYPES_PASS_H

namespace clspv {
struct SpecializeImageTypesPass
    : llvm::PassInfoMixin<SpecializeImageTypesPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

  enum ResultType { kNotImage, kNotSpecialized, kSpecialized };

private:
  // Returns the specialized image type for |arg|.
  std::pair<ResultType, llvm::Type *> RemapType(llvm::Argument *arg);

  // Returns the specialized image type for operand |operand_no| in |value|.
  std::pair<ResultType, llvm::Type *> RemapUse(llvm::Value *value,
                                               unsigned operand_no);

  // Specializes |arg| as |new_type|. Recursively updates the use chain.
  void SpecializeArg(llvm::Function *f, llvm::Argument *arg,
                     llvm::Type *new_type);

  // Returns a replacement image builtin function for the specialized type
  // |type|.
  llvm::Function *ReplaceImageBuiltin(llvm::Function *f,
                                      Builtins::FunctionInfo info,
                                      llvm::StructType *type);

  // Rewrites |f| using the |remapped_args_| to determine to updated types.
  void RewriteFunction(llvm::Function *f);

  // Tracks the generation of specialized types so they are not further
  // specialized.
  llvm::DenseSet<llvm::Type *> specialized_images_;

  // Maps an argument to a specialized type.
  llvm::DenseMap<llvm::Argument *, llvm::Type *> remapped_args_;

  // Tracks which functions need rewritten due to modified arguments.
  llvm::DenseSet<llvm::Function *> functions_to_modify_;

  llvm::DenseSet<llvm::Value *> visited_;
};
} // namespace clspv

#endif // _CLSPV_LIB_SPECIALIZE_IMAGE_TYPES_PASS_H
