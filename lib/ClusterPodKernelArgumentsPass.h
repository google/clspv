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

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

#ifndef _CLSPV_LIB_CLUSTER_POD_KERNEL_ARGUMENTS_PASS_H
#define _CLSPV_LIB_CLUSTER_POD_KERNEL_ARGUMENTS_PASS_H

namespace clspv {
struct ClusterPodKernelArgumentsPass
    : llvm::PassInfoMixin<ClusterPodKernelArgumentsPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  // Returns the type-mangled struct for global pod args. Only generates
  // unpacked structs currently. The type conversion code does not handle
  // packed structs propoerly. AutoPodArgsPass would also need updates to
  // support packed structs.
  llvm::StructType *GetTypeMangledPodArgsStruct(llvm::Module &M);

  // (Re-)Declares the global push constant variable with |mangled_struct_ty|
  // as the last member.
  void RedeclareGlobalPushConstants(llvm::Module &M,
                                    llvm::StructType *mangled_struct_ty);

  // Converts the corresponding elements of the global push constants for pod
  // args in member |index| of |pod_struct|.
  llvm::Value *ConvertToType(llvm::Module &M, llvm::StructType *pod_struct,
                             unsigned index, llvm::IRBuilder<> &builder);

  // Builds |dst_type| from |elements|, where |elements| is a vector i32 loads.
  llvm::Value *BuildFromElements(llvm::Module &M, llvm::IRBuilder<> &builder,
                                 llvm::Type *dst_type, uint64_t base_offset,
                                 uint64_t base_index,
                                 const std::vector<llvm::Value *> &elements);
};
} // namespace clspv

#endif // _CLSPV_LIB_CLUSTER_POD_KERNEL_ARGUMENTS_PASS_H
