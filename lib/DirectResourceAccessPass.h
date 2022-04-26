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

#ifndef _CLSPV_LIB_DIRECT_RESOURCE_ACCESS_PASS_H
#define _CLSPV_LIB_DIRECT_RESOURCE_ACCESS_PASS_H

namespace clspv {
struct DirectResourceAccessPass
    : llvm::PassInfoMixin<DirectResourceAccessPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  // For each kernel argument that will map to a resource variable (descriptor),
  // try to rewrite the uses of the argument as a direct access of the resource.
  // We can only do this if all the callees of the function use the same
  // resource access value for that argument.  Returns true if the module
  // changed.
  bool RewriteResourceAccesses(llvm::Function *fn);

  // Rewrite uses of this resrouce-based arg if all the callers pass in the
  // same resource access.  Returns true if the module changed.
  bool RewriteAccessesForArg(llvm::Function *fn, int arg_index,
                             llvm::Argument &arg);
};
} // namespace clspv

#endif // _CLSPV_LIB_DIRECT_RESOURCE_ACCESS_PASS_H
