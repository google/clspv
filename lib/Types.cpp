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

#include "Types.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DerivedTypes.h"

using namespace clspv;
using namespace llvm;

bool clspv::IsSamplerType(llvm::Type *type, llvm::Type **struct_type_ptr) {
  bool isSamplerType = false;
  if (PointerType *TmpArgPTy = dyn_cast<PointerType>(type)) {
    if (StructType *STy = dyn_cast<StructType>(TmpArgPTy->getElementType())) {
      if (STy->isOpaque()) {
        if (STy->getName().equals("opencl.sampler_t")) {
          isSamplerType = true;
          if (struct_type_ptr)
            *struct_type_ptr = STy;
        }
      }
    }
  }
  return isSamplerType;
}

bool clspv::IsImageType(llvm::Type *type, llvm::Type **struct_type_ptr) {
  bool isImageType = false;
  if (PointerType *TmpArgPTy = dyn_cast<PointerType>(type)) {
    if (StructType *STy = dyn_cast<StructType>(TmpArgPTy->getElementType())) {
      if (STy->isOpaque()) {
        if (STy->getName().startswith("opencl.image2d_ro_t") ||
            STy->getName().startswith("opencl.image2d_wo_t") ||
            STy->getName().startswith("opencl.image3d_ro_t") ||
            STy->getName().startswith("opencl.image3d_wo_t")) {
          isImageType = true;
          if (struct_type_ptr)
            *struct_type_ptr = STy;
        }
      }
    }
  }
  return isImageType;
}

uint32_t clspv::ImageDimensionality(Type *type) {
  Type *ty = nullptr;
  if (IsImageType(type, &ty)) {
    if (auto struct_ty = dyn_cast_or_null<StructType>(ty)) {
      if (struct_ty->getName().contains("image2d"))
        return 2;
      if (struct_ty->getName().contains("image3d"))
        return 3;
    }
  }

  return 0;
}

bool clspv::IsSampledImageType(Type *type) {
  Type *ty = nullptr;
  if (IsImageType(type, &ty)) {
    if (auto struct_ty = dyn_cast_or_null<StructType>(ty)) {
      if (struct_ty->getName().contains(".sampled"))
        return true;
    }
  }

  return false;
}

bool clspv::IsFloatImageType(Type *type) {
  return IsImageType(type) && !IsIntImageType(type) && !IsUintImageType(type);
}

bool clspv::IsIntImageType(Type *type) {
  Type *ty = nullptr;
  if (IsImageType(type, &ty)) {
    if (auto struct_ty = dyn_cast_or_null<StructType>(ty)) {
      if (struct_ty->getName().contains(".int"))
        return true;
    }
  }

  return false;
}

bool clspv::IsUintImageType(Type *type) {
  Type *ty = nullptr;
  if (IsImageType(type, &ty)) {
    if (auto struct_ty = dyn_cast_or_null<StructType>(ty)) {
      if (struct_ty->getName().contains(".uint"))
        return true;
    }
  }

  return false;
}
