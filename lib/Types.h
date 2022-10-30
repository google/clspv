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

#include "llvm/ADT/DenseMap.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"

#include "spirv/unified1/spirv.hpp"

namespace clspv {

// Returns the inferred type of |v|.
//
// If the type of |v\ is an opaque pointer, this function traverses the uses of
// |v| to determine the appropriate type.
// Returns nullptr if a type cannot be inferred.
llvm::Type *InferType(llvm::Value *v, llvm::LLVMContext &context,
                      llvm::DenseMap<llvm::Value *, llvm::Type *> *cache);

// Returns true if the given type is descriptor resource.
// Slight nuance with physical storage buffers.
bool IsResourceType(llvm::Type *type);

// Returns true if the given type is a physical storage buffer.
bool IsPhysicalSSBOType(llvm::Type *type);

// Returns true if the given type is a sampler type.
bool IsSamplerType(llvm::Type *type);

// Returns true if the given type is an image type.
bool IsImageType(llvm::Type *type);

// Returns the dimensionality of the image type. If |type| is not an
// image, returns spv::DimMax.
spv::Dim ImageDimensionality(llvm::Type *type);

// Returns the dimensionality of the image type. If |type| is not an
// image, returns 0.
uint32_t ImageNumDimensions(llvm::Type *type);

// Returns true if the given type is an array image type.
bool IsArrayImageType(llvm::Type *type);

// Returns true if the given type is a sampled image type. Can only
// return true after image specialization.
bool IsSampledImageType(llvm::Type *type);

// Returns true if the given type is a storage image type. This is the case
// for read_write and write_only images.
bool IsStorageImageType(llvm::Type *type);

bool IsStorageTexelBufferImageType(llvm::StructType *type);

// Returns true if the given type is a float image type.
// Before image specialization, all images are considered float images.
bool IsFloatImageType(llvm::Type *type);

// Returns true if the given type is an int image type.
// Can only return true after image specialization.
bool IsIntImageType(llvm::Type *type);

// Returns true if the given type is an uint image type.
// Can only return true after image specialization.
bool IsUintImageType(llvm::Type *type);

// Returns true if the given type is a write only image type.
// Only reliable after image specialization.
bool IsWriteOnlyImageType(llvm::Type *type);

// Returns true if pointers in the module are 64-bit.
bool PointersAre64Bit(llvm::Module &m);

} // namespace clspv

#endif
