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

#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

#ifndef _CLSPV_LIB_REWRITEPACKEDSTRUCTS_PASS_H
#define _CLSPV_LIB_RewritePackedStructs_PASS_H

namespace clspv {
struct RewritePackedStructs : llvm::PassInfoMixin<RewritePackedStructs> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  // Helpers for rewritting types.

  /// Get a struct of i8 array equivalent for this type, if it uses a packed
  /// struct. Returns nullptr if no rewritting is required.
  llvm::Type *getEquivalentType(llvm::Type *Ty);

  /// Implementation details of getEquivalentType.
  llvm::Type *getEquivalentTypeImpl(llvm::Type *Ty);

  /// Return the equivalent type for @p Ty or @p Ty if no rewriting is needed.
  llvm::Type *getEquivalentTypeOrSelf(llvm::Type *Ty) {
    auto *EquivalentTy = getEquivalentType(Ty);
    return EquivalentTy ? EquivalentTy : Ty;
  }

private:
  // High-level implementation details of runOnModule.

  /// Rewrite non opaque functions.
  bool runOnFunction(llvm::Function &F);

  /// Rewrite opaque functions.
  bool runOnOpaqueFunction(llvm::Function &F);

  /// Create an alternative version of @p F that doesn't have mapped struct
  /// buffers.
  llvm::Function *convertUserDefinedFunction(llvm::Function &F);

  bool structsShouldBeLowered(llvm::Function &F);

private:
  /// A map between struct types and their equivalent representation.
  llvm::DenseMap<llvm::Type *, llvm::Type *> TypeMap;

  llvm::DenseMap<llvm::Value *, llvm::Type *> type_cache_;

  const llvm::DataLayout *DL;
};
} // namespace clspv

#endif // _CLSPV_LIB_RewritePackedStructs_PASS_H
