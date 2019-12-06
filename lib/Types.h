// Copyright 2019 The Clspv Authors. All rights reserved.
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

#ifndef CLSPV_LIB_TYPES_H
#define CLSPV_LIB_TYPES_H

#include "llvm/IR/Type.h"

namespace clspv {

// Returns true if the given type is a sampler type.  If it is, then the
// struct type is sent back through the ptr argument.
bool IsSamplerType(llvm::Type *type, llvm::Type **struct_type_ptr = nullptr);

// Returns true if the given type is a image type.  If it is, then the
// struct type is sent back through the ptr argument.
bool IsImageType(llvm::Type *type, llvm::Type **struct_type_ptr = nullptr);

// Returns the dimensionality of the image type. If |type| is not an image,
// returns 0.
uint32_t ImageDimensionality(llvm::Type *type);

// Returns true if the given type is a sampled image type. Can only return true
// after image specialization.
bool IsSampledImageType(llvm::Type *type);

// Returns true if the given type is a float image type.
// Before image specialization, all images are considered float images.
bool IsFloatImageType(llvm::Type *type);

// Returns true if the given type is an int image type.
// Can only return true after image specialization.
bool IsIntImageType(llvm::Type *type);

// Returns true if the given type is an uint image type.
// Can only return true after image specialization.
bool IsUintImageType(llvm::Type *type);

} // namespace clspv

#endif
