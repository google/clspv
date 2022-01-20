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

#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Type.h"

#include "spirv/unified1/spirv.hpp"

namespace clspv {

// Returns true if the given struct type is a sampler type.
bool IsSamplerType(llvm::StructType *type);

// Returns true if the given type is a sampler type.  If it is, then the
// struct type is sent back through the ptr argument.
bool IsSamplerType(llvm::Type *type, llvm::Type **struct_type_ptr = nullptr);

// Returns true if the given struct type is an image type.
bool IsImageType(llvm::StructType *type);

// Returns true if the given type is a image type.  If it is, then the
// struct type is sent back through the ptr argument.
bool IsImageType(llvm::Type *type, llvm::Type **struct_type_ptr = nullptr);

// Returns the dimensionality of the image struct type. If |type| is not an
// image, returns spv::DimMax.
spv::Dim ImageDimensionality(llvm::StructType *type);

// Returns the dimensionality of the image type. If |type| is not an image,
// returns spv::DimMax.
spv::Dim ImageDimensionality(llvm::Type *type);

// Returns the dimensionality of the image struct type. If |type| is not an
// image, returns 0.
uint32_t ImageNumDimensions(llvm::StructType *type);

// Returns the dimensionality of the image type. If |type| is not an image,
// returns 0.
uint32_t ImageNumDimensions(llvm::Type *type);

// Returns true if the given type is an array image type.
bool IsArrayImageType(llvm::Type *type);

// Returns true if the given struct type is a sampled image type. Can only
// return true after image specialization.
bool IsSampledImageType(llvm::StructType *type);

// Returns true if the given type is a sampled image type. Can only return true
// after image specialization.
bool IsSampledImageType(llvm::Type *type);

// Returns true if the given type is a storage image type. This is the case
// for read_write and write_only images.
bool IsStorageImageType(llvm::Type *type);

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
