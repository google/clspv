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

#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

#ifndef _CLSPV_LIB_MULTI_VERSION_UBO_FUNCTIONS_PASS_H
#define _CLSPV_LIB_MULTI_VERSION_UBO_FUNCTIONS_PASS_H

namespace clspv {
struct MultiVersionUBOFunctionsPass
    : llvm::PassInfoMixin<MultiVersionUBOFunctionsPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  // Struct for tracking specialization information.
  struct ResourceInfo {
    // The specific argument.
    llvm::Argument *arg;
    // The resource var base call.
    llvm::CallInst *base;
    // Series of GEPs that operate on |base|.
    std::vector<llvm::GetElementPtrInst *> indices;
  };

  // Analyzes the call, |user|, to |fn| in terms of its UBO arguments. Returns
  // true if |user| can be transformed into a specialized function.
  //
  // Currently, this function is only successful in analyzing GEP chains to a
  // resource variable.
  bool AnalyzeCall(llvm::Function *fn, llvm::CallInst *user,
                   std::vector<ResourceInfo> *resources);

  // Inlines |call|.
  void InlineCallSite(llvm::CallInst *call);

  // Transforms the call to |fn| into a specialized call based on |resources|.
  // Replaces |call| with a call to the specialized version.
  void SpecializeCall(llvm::Function *fn, llvm::CallInst *call,
                      const std::vector<ResourceInfo> &resources, size_t id);

  // Adds extra arguments to |fn| by rebuilding the entire function.
  llvm::Function *
  AddExtraArguments(llvm::Function *fn,
                    const std::vector<llvm::Value *> &extra_args);
};
} // namespace clspv

#endif // _CLSPV_LIB_MULTI_VERSION_UBO_FUNCTIONS_PASS_H
