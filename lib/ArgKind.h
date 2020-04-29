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
PodArgImpl GetPodArgsImpl(llvm::Function &F);

// Returns the ArgKind for pod args in kernel |F|.
ArgKind GetArgKindForPodArgs(llvm::Function &F);

// Returns the ArgKind for |Arg|.
ArgKind GetArgKind(llvm::Argument &Arg);

// Returns true if the given type is a pointer-to-local type.
bool IsLocalPtr(llvm::Type *type);

using ArgIdMapType = llvm::DenseMap<const llvm::Argument *, int>;

// Returns a mapping from pointer-to-local Argument to a specialization constant
// ID for that argument's array size.  The lowest value allocated is 3.
//
// The mapping is as follows:
// - The first index used is 3.
// - There are no gaps in the list of used indices.
// - Arguments from earlier kernel bodies have lower indices than arguments from
//   later kernel bodies.
// - Lower-numbered arguments have lower indices than higher-numbered arguments
//   in the same function.
// Note that this mapping is stable as long as the order of kernel bodies is
// retained, and the number and order of pointer-to-local arguments is retained.
ArgIdMapType AllocateArgSpecIds(llvm::Module &M);

} // namespace clspv

#endif
