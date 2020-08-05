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

// Returns the size of global push constants.
uint64_t GlobalPushConstantsSize(llvm::Module &);
} // namespace clspv

#endif // #ifndef CLSPV_LIB_PUSH_CONSTANT_H_
