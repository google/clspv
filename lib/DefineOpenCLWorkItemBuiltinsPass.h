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

#include "clspv/AddressSpace.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

#ifndef _CLSPV_LIB_DEFINE_OPENCL_WORKITEM_BUILTINS_PASS_H
#define _CLSPV_LIB_DEFINE_OPENCL_WORKITEM_BUILTINS_PASS_H

namespace clspv {
struct DefineOpenCLWorkItemBuiltinsPass
    : llvm::PassInfoMixin<DefineOpenCLWorkItemBuiltinsPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

  llvm::GlobalVariable *createGlobalVariable(llvm::Module &M,
                                             llvm::StringRef GlobalVarName,
                                             llvm::Type *Ty,
                                             AddressSpace::Type AddrSpace);

  bool defineMappedBuiltin(llvm::Module &M, llvm::StringRef FuncName,
                           llvm::StringRef GlobalVarName, unsigned DefaultValue,
                           AddressSpace::Type AddrSpace,
                           llvm::ArrayRef<llvm::StringRef> dependents);

  bool defineGlobalIDBuiltin(llvm::Module &M);
  bool defineNumGroupsBuiltin(llvm::Module &M);
  bool defineGroupIDBuiltin(llvm::Module &M);
  bool defineGlobalSizeBuiltin(llvm::Module &M);
  bool defineGlobalOffsetBuiltin(llvm::Module &M);
  bool defineGlobalLinearIDBuiltin(llvm::Module &M);
  bool defineLocalLinearIDBuiltin(llvm::Module &M);
  bool defineWorkDimBuiltin(llvm::Module &M);
  bool defineEnqueuedLocalSizeBuiltin(llvm::Module &M);
  bool defineMaxSubGroupSizeBuiltin(llvm::Module &M);
  bool defineEnqueuedNumSubGroupsBuiltin(llvm::Module &M);

  bool addWorkgroupSizeIfRequired(llvm::Module &M);
};
} // namespace clspv

#endif // _CLSPV_LIB_DEFINE_OPENCL_WORKITEM_BUILTINS_PASS_H
