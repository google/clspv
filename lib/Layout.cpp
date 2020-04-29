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

#include "clspv/Option.h"

#include "Layout.h"

using namespace llvm;

namespace {
bool isScalarType(Type *type) {
  return type->isIntegerTy() || type->isFloatTy();
}

uint64_t structAlignment(StructType *type,
                         std::function<uint64_t(Type *)> alignFn) {
  uint64_t maxAlign = 1;
  for (unsigned i = 0; i < type->getStructNumElements(); i++) {
    uint64_t align = alignFn(type->getStructElementType(i));
    maxAlign = std::max(align, maxAlign);
  }
  return maxAlign;
}

uint64_t scalarAlignment(Type *type) {
  // A scalar of size N has a scalar alignment of N.
  if (isScalarType(type)) {
    return type->getScalarSizeInBits() / 8;
  }

  // A vector or matrix type has a scalar alignment equal to that of its
  // component type.
  if (auto vec_type = dyn_cast<VectorType>(type)) {
    return scalarAlignment(vec_type->getElementType());
  }

  // An array type has a scalar alignment equal to that of its element type.
  if (type->isArrayTy()) {
    return scalarAlignment(type->getArrayElementType());
  }

  // A structure has a scalar alignment equal to the largest scalar alignment of
  // any of its members.
  if (type->isStructTy()) {
    return structAlignment(cast<StructType>(type), scalarAlignment);
  }

  llvm_unreachable("Unsupported type");
}

uint64_t baseAlignment(Type *type) {
  // A scalar has a base alignment equal to its scalar alignment.
  if (isScalarType(type)) {
    return scalarAlignment(type);
  }

  if (auto vec_type = dyn_cast<VectorType>(type)) {
    unsigned numElems = vec_type->getNumElements();

    // A two-component vector has a base alignment equal to twice its scalar
    // alignment.
    if (numElems == 2) {
      return 2 * scalarAlignment(type);
    }
    // A three- or four-component vector has a base alignment equal to four
    // times its scalar alignment.
    if ((numElems == 3) || (numElems == 4)) {
      return 4 * scalarAlignment(type);
    }
  }

  // An array has a base alignment equal to the base alignment of its element
  // type.
  if (type->isArrayTy()) {
    return baseAlignment(type->getArrayElementType());
  }

  // A structure has a base alignment equal to the largest base alignment of any
  // of its members.
  if (type->isStructTy()) {
    return structAlignment(cast<StructType>(type), baseAlignment);
  }

  // TODO A row-major matrix of C columns has a base alignment equal to the base
  // alignment of a vector of C matrix components.
  // TODO A column-major matrix has a base alignment equal to the base alignment
  // of the matrix column type.

  llvm_unreachable("Unsupported type");
}

uint64_t extendedAlignment(Type *type) {
  // A scalar, vector or matrix type has an extended alignment equal to its base
  // alignment.
  // TODO matrix type
  if (isScalarType(type) || type->isVectorTy()) {
    return baseAlignment(type);
  }

  // An array or structure type has an extended alignment equal to the largest
  // extended alignment of any of its members, rounded up to a multiple of 16
  if (type->isStructTy()) {
    auto salign = structAlignment(cast<StructType>(type), extendedAlignment);
    return alignTo(salign, 16);
  }

  if (type->isArrayTy()) {
    auto salign = extendedAlignment(type->getArrayElementType());
    return alignTo(salign, 16);
  }

  llvm_unreachable("Unsupported type");
}

uint64_t standardAlignment(Type *type, spv::StorageClass sclass) {
  // If the scalarBlockLayout feature is enabled on the device then every member
  // must be aligned according to its scalar alignment
  if (clspv::Option::ScalarBlockLayout()) {
    return scalarAlignment(type);
  }

  // All vectors must be aligned according to their scalar alignment
  if (type->isVectorTy()) {
    return scalarAlignment(type);
  }

  // If the uniformBufferStandardLayout feature is not enabled on the device,
  // then any member of an OpTypeStruct with a storage class of Uniform and a
  // decoration of Block must be aligned according to its extended alignment.
  if (!clspv::Option::Std430UniformBufferLayout() &&
      sclass == spv::StorageClassUniform) {
    return extendedAlignment(type);
  }

  // Every other member must be aligned according to its base alignment
  return baseAlignment(type);
}

bool improperlyStraddles(const DataLayout &DL, Type *type, unsigned offset) {
  assert(type->isVectorTy());

  auto size = DL.getTypeStoreSize(type);

  // It is a vector with total size less than or equal to 16 bytes, and has
  // Offset decorations placing its first byte at F and its last byte at L,
  // where floor(F / 16) != floor(L / 16).
  if ((size <= 16) && (offset % 16 + size > 16)) {
    return true;
  }

  // It is a vector with total size greater than 16 bytes and has its Offset
  // decorations placing its first byte at a non-integer multiple of 16
  if ((size > 16) && (offset % 16 != 0)) {
    return true;
  }

  return false;
}
} // namespace

namespace clspv {

// See 14.5 Shader Resource Interface in Vulkan spec
bool isValidExplicitLayout(Module &M, StructType *STy, unsigned Member,
                           spv::StorageClass SClass, unsigned Offset,
                           unsigned PreviousMemberOffset) {

  auto MemberType = STy->getElementType(Member);
  auto Align = standardAlignment(MemberType, SClass);
  auto &DL = M.getDataLayout();

  // The Offset decoration of any member must be a multiple of its alignment
  if (Offset % Align != 0) {
    return false;
  }

  // TODO Any ArrayStride or MatrixStride decoration must be a multiple of the
  // alignment of the array or matrix as defined above

  if (!clspv::Option::ScalarBlockLayout()) {
    // Vectors must not improperly straddle, as defined above
    if (MemberType->isVectorTy() &&
        improperlyStraddles(DL, MemberType, Offset)) {
      return true;
    }

    // The Offset decoration of a member must not place it between the end
    // of a structure or an array and the next multiple of the alignment of that
    // structure or array
    if (Member > 0) {
      auto PType = STy->getElementType(Member - 1);
      if (PType->isStructTy() || PType->isArrayTy()) {
        auto PAlign = standardAlignment(PType, SClass);
        if (Offset - PreviousMemberOffset < PAlign) {
          return false;
        }
      }
    }
  }

  return true;
}

bool isValidExplicitLayout(llvm::Module &M, llvm::StructType *STy,
                           spv::StorageClass SClass) {
  auto const &DL = M.getDataLayout();
  const auto StructLayout = DL.getStructLayout(STy);
  bool ok = true;
  auto previous_offset = 0;
  for (unsigned i = 0; ok && i < STy->getNumElements(); i++) {
    auto offset = StructLayout->getElementOffset(i);
    ok &= isValidExplicitLayout(M, STy, i, SClass, offset, previous_offset);
    previous_offset = offset;
  }

  return ok;
}
} // namespace clspv
