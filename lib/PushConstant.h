// Copyright 2020 The Clspv Authors. All rights reserved.
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

#ifndef CLSPV_LIB_PUSH_CONSTANT_H_
#define CLSPV_LIB_PUSH_CONSTANT_H_

#include "clspv/PushConstant.h"

#include "llvm/ADT/ArrayRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Value.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"

namespace clspv {

// Returns a type valid in the module passed for the push constant specified.
llvm::Type *GetPushConstantType(llvm::Module &, PushConstant);

// Returns a pointer to the push constant passed. Instructions to create the
// pointer are appended to the basic block provided.
llvm::Value *GetPushConstantPointer(llvm::BasicBlock *, PushConstant,
                                    const llvm::ArrayRef<llvm::Value *> & = {});

// Returns true if any global push constant is used.
bool UsesGlobalPushConstants(llvm::Module &);

// Returns true if an implementation of get_global_offset() is needed.
bool ShouldDeclareGlobalOffsetPushConstant(llvm::Module &);

// Returns true if an implementation of get_enqueued_local_size() is needed.
bool ShouldDeclareEnqueuedLocalSizePushConstant(llvm::Module &);

// Returns true if non-uniform NDRange get_global_size() is needed.
bool ShouldDeclareGlobalSizePushConstant(llvm::Module &);

// Returns true if non-uniform NDRange region offset is needed.
bool ShouldDeclareRegionOffsetPushConstant(llvm::Module &);

// Returns true if non-uniform NDRange get_num_groups() is needed.
bool ShouldDeclareNumWorkgroupsPushConstant(llvm::Module &);

// Returns true if non-uniform NDRange region group offset is needed.
bool ShouldDeclareRegionGroupOffsetPushConstant(llvm::Module &);

// Returns true if module-scope constants pointer is needed.
bool ShouldDeclareModuleConstantsPointerPushConstant(llvm::Module &);

// Returns the type of the global push constants struct.
llvm::StructType *GlobalPushConstantsType(llvm::Module &);

// (Re-)Declares the global push constant variable with |mangled_struct_ty|
// as the last member.
void RedeclareGlobalPushConstants(llvm::Module &M,
                                  llvm::StructType *mangled_struct_ty,
                                  int push_constant_type);

// Converts the corresponding elements of the global push constants for pod
// args in member |index| of |pod_struct|.
llvm::Value *ConvertToType(llvm::Module &M, llvm::StructType *pod_struct,
                           unsigned index, llvm::IRBuilder<> &builder);

// Builds |dst_type| from |elements|, where |elements| is a vector i32 loads.
llvm::Value *BuildFromElements(llvm::Module &M, llvm::IRBuilder<> &builder,
                               llvm::Type *dst_type, uint64_t base_offset,
                               uint64_t base_index,
                               const std::vector<llvm::Value *> &elements);

} // namespace clspv

#endif // #ifndef CLSPV_LIB_PUSH_CONSTANT_H_
