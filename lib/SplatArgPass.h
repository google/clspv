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

#include "Builtins.h"

#ifndef _CLSPV_LIB_SPLAT_ARG_PASS_PASS_H
#define _CLSPV_LIB_SPLAT_ARG_PASS_PASS_H

namespace clspv {
struct SplatArgPass : llvm::PassInfoMixin<SplatArgPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

  std::string getSplatName(const Builtins::FunctionInfo &func_info,
                           const Builtins::ParamTypeInfo &param_info,
                           bool three_params);
  llvm::Function *getReplacementFunction(llvm::Function &F,
                                         const std::string &NewCallName);
  void replaceCall(llvm::Function *NewCallee, llvm::CallInst *Call);
};
} // namespace clspv

#endif // _CLSPV_LIB_SPLAT_ARG_PASS_PASS_H
