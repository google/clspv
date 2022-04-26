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

#ifndef _CLSPV_LIB_UBO_TYPE_TRANSFORM_PASS_H
#define _CLSPV_LIB_UBO_TYPE_TRANSFORM_PASS_H

namespace clspv {
struct UBOTypeTransformPass : llvm::PassInfoMixin<UBOTypeTransformPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  // Returns the remapped version of |type| that satisfies UBO requirements.
  // |rewrite| indicates whether the type can be rewritten or just rebuilt.
  llvm::Type *MapType(llvm::Type *type, llvm::Module &M, bool rewrite);
  llvm::Type *RebuildType(llvm::Type *type, llvm::Module &M) {
    return MapType(type, M, false);
  }

  // Returns the remapped version of |type| that satisfies UBO requirements.
  // |rewrite| indicates whether the type can be rewritten or just rebuilt.
  llvm::StructType *MapStructType(llvm::StructType *struct_ty, llvm::Module &M,
                                  bool rewrite);

  // Performs type mutation on |M|. Returns true if |M| was modified.
  bool RemapTypes(llvm::Module &M);

  // Performs type mutation for functions that require it. Returns true if the
  // module is modified.
  //
  // If a function requires type mutation it will be replaced by a new
  // function. The function's basic blocks are moved into the new function and
  // all metadata is copied.
  bool
  RemapFunctions(llvm::SmallVectorImpl<llvm::Function *> *functions_to_modify,
                 llvm::Module &M);

  // Rebuilds global variables if their types require transformation. Returns
  // true if the module is modified.
  bool RemapGlobalVariables(
      llvm::SmallVectorImpl<llvm::GlobalVariable *> *variables_to_modify,
      llvm::Module &M);

  // Performs type mutation on |user|. Recursively fixes operands of |user|.
  // Returns true if the module is modified.
  bool RemapUser(llvm::User *user, llvm::Module &M);

  // Mutates the type of |value|. Returns true if the module is modified.
  bool RemapValue(llvm::Value *value, llvm::Module &M);

  // Maps and rebuilds |constant| to match its mapped type. Returns true if the
  // module if modified.
  bool RemapConstant(llvm::Constant *constant, llvm::Module &M);

  // Rebuild |constant| as a constant with |remapped_ty| type. Returns the
  // rebuilt constant.
  llvm::Constant *RebuildConstant(llvm::Constant *constant,
                                  llvm::Type *remapped_ty, llvm::Module &M);

  // Performs final modifications on functions that were replaced. Fixes names
  // and use-def chains.
  void
  FixupFunctions(const llvm::ArrayRef<llvm::Function *> &functions_to_modify,
                 llvm::Module &M);

  // Replaces and deletes modified global variables.
  void FixupGlobalVariables(
      const llvm::ArrayRef<llvm::GlobalVariable *> &variables_to_modify);

  // Maps a type to its UBO type.
  llvm::DenseMap<llvm::Type *, llvm::Type *> remapped_types_;

  // Prevents infinite recusion.
  llvm::DenseSet<llvm::Type *> deferred_types_;

  // Maps a function to its replacement.
  llvm::DenseMap<llvm::Function *, llvm::Function *> function_replacements_;

  // Maps a global value to its replacement.
  llvm::DenseMap<llvm::Constant *, llvm::Constant *> remapped_globals_;

  // Whether char arrays are supported in UBOs.
  bool support_int8_array_;
};
} // namespace clspv

#endif // _CLSPV_LIB_UBO_TYPE_TRANSFORM_PASS_H
