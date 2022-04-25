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

#ifndef _CLSPV_LIB_SHARE_MODULE_SCOPE_VARIABLES_PASS_H
#define _CLSPV_LIB_SHARE_MODULE_SCOPE_VARIABLES_PASS_H

namespace clspv {
struct ShareModuleScopeVariablesPass
    : llvm::PassInfoMixin<ShareModuleScopeVariablesPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

  typedef llvm::DenseMap<llvm::Function *, llvm::UniqueVector<llvm::Function *>>
      EntryPointMap;

private:
  // Maps functions to entry points that can call them including themselves.
  void MapEntryPoints(llvm::Module &M);

  // Traces the callable functions from |function| and maps them to
  // |entry_point|.
  void TraceFunction(llvm::Function *function, llvm::Function *entry_point);

  // Attempts to share module scope variables. Returns true if any variables are
  // shared.  Shares variables of the same type that are used by
  // non-intersecting sets of kernels.
  bool ShareModuleScopeVariables(llvm::Module &M);

  // Collects the entry points that can reach |value| into |user_entry_points|.
  void CollectUserEntryPoints(
      llvm::Value *value,
      llvm::UniqueVector<llvm::Function *> *user_entry_points);

  // Returns true if there is an intersection between the |user_functions| and
  // |other_entry_points|.
  bool HasSharedEntryPoints(
      const llvm::DenseSet<llvm::Function *> &user_functions,
      const llvm::UniqueVector<llvm::Function *> &other_entry_points);

  EntryPointMap function_to_entry_points_;
};
} // namespace clspv

#endif // _CLSPV_LIB_SHARE_MODULE_SCOPE_VARIABLES_PASS_H
