// Copyright 2017 The Clspv Authors. All rights reserved.
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

#ifndef CLSPV_LIB_ARGKIND_H_
#define CLSPV_LIB_ARGKIND_H_

#include "llvm/ADT/DenseMap.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"

#include "clspv/ArgKind.h"

namespace clspv {

// Enum for how pod args are implemented. Gets added as metadata to each
// kernel.
enum PodArgImpl {
  kSSBO,
  kUBO,
  kPushConstant,
  // Shared interface across all shaders.
  kGlobalPushConstant,
};

// Returns the style of pod args used by |F|. Note that |F| must be a kernel.
PodArgImpl GetPodArgsImpl(const llvm::Function &F);

// Returns the ArgKind for pod args in kernel |F|.
ArgKind GetArgKindForPodArgs(const llvm::Function &F);

// Returns the ArgKind for |Arg|.
ArgKind GetArgKind(llvm::Argument &Arg, llvm::Type *data_type = nullptr);

// Returns true if the given type is a pointer-to-local type.
bool IsLocalPtr(llvm::Type *type);

} // namespace clspv

#endif
