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

#include "Builtins.h"
#include "Constants.h"
#include "Types.h"
#include "spirv/unified1/spirv.hpp"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"

using namespace clspv;
using namespace llvm;

Type *clspv::InferType(Value *v, LLVMContext &context,
                       DenseMap<Value *, Type *> *cache) {
  // Non-pointer types are reflexive.
  if (!isa<PointerType>(v->getType()))
    return v->getType();

  // TODO: #816 remove this after final transition
  // Non-opaque pointer use the element type.
  if (!v->getType()->isOpaquePointerTy())
    return v->getType()->getNonOpaquePointerElementType();

  // Null ptr constants cannot be inferred from other uses.
  if (isa<ConstantPointerNull>(*v)) {
    return nullptr;
  }

  auto iter = cache->find(v);
  if (iter != cache->end()) {
    return iter->second;
  }

  auto CacheType = [cache, v](Type *ty) {
    (*cache)[v] = ty;
    return ty;
  };

  // Return the source data interpretation type.
  if (auto *gep = dyn_cast<GEPOperator>(v)) {
    return CacheType(gep->getResultElementType());
  } else if (auto *alloca = dyn_cast<AllocaInst>(v)) {
    if (!alloca->getAllocatedType()->isPointerTy()) {
      return CacheType(alloca->getAllocatedType());
    }
  } else if (auto *gv = dyn_cast<GlobalVariable>(v)) {
    return CacheType(gv->getValueType());
  }

  // Special resource-related functions. The last parameter of each function is
  // the inferred type.
  if (auto *call = dyn_cast<CallInst>(v)) {
    auto &info = clspv::Builtins::Lookup(call->getCalledFunction());
    switch (info.getType()) {
    case clspv::Builtins::kClspvSamplerVarLiteral:
      return CacheType(
          call->getArgOperand(clspv::ClspvOperand::kSamplerDataType)
              ->getType());
    case clspv::Builtins::kClspvResource:
      return CacheType(
          call->getArgOperand(clspv::ClspvOperand::kResourceDataType)
              ->getType());
    case clspv::Builtins::kClspvLocal:
      return CacheType(
          call->getArgOperand(clspv::ClspvOperand::kWorkgroupDataType)
              ->getType());
    default:
      break;
    }
  }

  std::vector<std::pair<User *, unsigned>> worklist;
  for (auto &use : v->uses()) {
    worklist.push_back(std::make_pair(use.getUser(), use.getOperandNo()));
  }

  DenseSet<Value *> seen;
  while (!worklist.empty()) {
    User *user = worklist.back().first;
    unsigned operand = worklist.back().second;
    worklist.pop_back();
    bool isPointerTy = false;
    if (!seen.insert(user).second) {
      continue;
    }

    if (auto *GEP = dyn_cast<GEPOperator>(user)) {
      return CacheType(GEP->getSourceElementType());
    } else if (auto *load = dyn_cast<LoadInst>(user)) {
      if (!load->getType()->isPointerTy()) {
        return CacheType(load->getType());
      }
      isPointerTy = true;
    } else if (auto *store = dyn_cast<StoreInst>(user)) {
      if (!store->getValueOperand()->getType()->isPointerTy()) {
        return CacheType(store->getValueOperand()->getType());
      } else if (!isa<ConstantPointerNull>(store->getValueOperand())) {
        isPointerTy = true;
      }
    } else if (auto *call = dyn_cast<CallInst>(user)) {
      auto &info = clspv::Builtins::Lookup(call->getCalledFunction());
      // TODO: remaining builtins
      // TODO: kSpirvCopyMemory
      switch (info.getType()) {
      case clspv::Builtins::kAtomicInit:
      case clspv::Builtins::kAtomicStore:
      case clspv::Builtins::kAtomicStoreExplicit: {
        // Data type is inferred from the "value" or "desired" operand.
        auto *data_param = call->getArgOperand(1);
        return CacheType(data_param->getType());
      }
      case clspv::Builtins::kAtomicCompareExchangeStrong:
      case clspv::Builtins::kAtomicCompareExchangeStrongExplicit:
      case clspv::Builtins::kAtomicCompareExchangeWeak:
      case clspv::Builtins::kAtomicCompareExchangeWeakExplicit: {
        // Data type inferred from "desired" operand.
        auto *data_param = call->getArgOperand(2);
        return CacheType(data_param->getType());
      }
      case clspv::Builtins::kVload:
        // Data type is the scalar return type.
        return CacheType(call->getType()->getScalarType());
      case clspv::Builtins::kVloadHalf:
      case clspv::Builtins::kVloadaHalf:
        return CacheType(Type::getHalfTy(context));
      case clspv::Builtins::kVstore: {
        // Data type is the scalar version of the "data" operand.
        auto *data_param = call->getArgOperand(0);
        return CacheType(data_param->getType()->getScalarType());
      }
      case clspv::Builtins::kVstoreHalf:
      case clspv::Builtins::kVstoreaHalf:
        return CacheType(Type::getHalfTy(context));
      case clspv::Builtins::kSincos:
      case clspv::Builtins::kModf:
      case clspv::Builtins::kFract:
        // Data type is the same as the return type.
        return CacheType(call->getType());
      case clspv::Builtins::kFrexp:
      case clspv::Builtins::kRemquo:
      case clspv::Builtins::kLgammaR: {
        // Data type is an i32 equivalent of the return type.
        // That is, same number of components.
        auto *int32Ty = Type::getIntNTy(context, 32);
        auto *data_ty = call->getType();
        if (auto vec_ty = dyn_cast<VectorType>(data_ty))
          return CacheType(VectorType::get(int32Ty, vec_ty));
        else
          return CacheType(int32Ty);
      }
      case clspv::Builtins::kBuiltinNone:
        if (!call->getCalledFunction()->isDeclaration()) {
          // See if the type can be inferred from the use in the called
          // function.
          auto *ty = InferType(call->getCalledFunction()->getArg(operand),
                               context, cache);
          if (ty)
            return CacheType(ty);
        }
        break;
      default:
        // Handle entire ranges of builtins here.
        if (BUILTIN_IN_GROUP(info.getType(), Image)) {
          // Data type is inferred through the mangling of the operand.
          auto param = info.getParameter(operand);
          assert(param.type_id == Type::StructTyID);
          auto struct_ty = StructType::getTypeByName(context, param.name);
          if (!struct_ty) {
            struct_ty = StructType::create(context, param.name);
          }
          return CacheType(struct_ty);
        } else if (BUILTIN_IN_GROUP(info.getType(), Atomic) ||
                   info.getType() == clspv::Builtins::kSpirvAtomicXor) {
          // TODO: handle atomic flag functions properly.
          // Data type is the same as the return type.
          return CacheType(call->getType());
        } else if (BUILTIN_IN_GROUP(info.getType(), Async)) {
          // Data type is inferred through the mangling of the operand.
          auto param = info.getParameter(operand);
          return CacheType(param.DataType(context));
        }
        break;
      }
    }

    // If the result is also a pointer, try to infer from further uses.
    if (user->getType()->isPointerTy() || isPointerTy) {
      // Handle stores with only pointer operands.
      if (auto *store = dyn_cast<StoreInst>(user)) {
        if (store->getPointerOperand() != v) {
          user = dyn_cast<User>(store->getPointerOperand());
        } else if (auto *value = dyn_cast<User>(store->getValueOperand())) {
          user = value;
        }
      }
      for (auto &use : user->uses()) {
        worklist.push_back(std::make_pair(use.getUser(), use.getOperandNo()));
      }
    }
  }
  return nullptr;
}

bool clspv::IsSamplerType(llvm::StructType *STy) {
  if (!STy) return false;
  if (STy->isOpaque()) {
    if (STy->getName().equals("opencl.sampler_t") ||
        STy->getName().equals("ocl_sampler")) {
      return true;
    }
  }
  return false;
}

bool clspv::IsImageType(llvm::StructType *STy) {
  if (!STy) return false;
  if (STy->isOpaque()) {
    if (STy->getName().startswith("opencl.image1d_ro_t") ||
        STy->getName().startswith("opencl.image1d_rw_t") ||
        STy->getName().startswith("opencl.image1d_wo_t") ||
        STy->getName().startswith("opencl.image1d_array_ro_t") ||
        STy->getName().startswith("opencl.image1d_array_rw_t") ||
        STy->getName().startswith("opencl.image1d_array_wo_t") ||
        STy->getName().startswith("opencl.image1d_buffer_ro_t") ||
        STy->getName().startswith("opencl.image1d_buffer_rw_t") ||
        STy->getName().startswith("opencl.image1d_buffer_wo_t") ||
        STy->getName().startswith("opencl.image2d_ro_t") ||
        STy->getName().startswith("opencl.image2d_rw_t") ||
        STy->getName().startswith("opencl.image2d_wo_t") ||
        STy->getName().startswith("opencl.image2d_array_ro_t") ||
        STy->getName().startswith("opencl.image2d_array_rw_t") ||
        STy->getName().startswith("opencl.image2d_array_wo_t") ||
        STy->getName().startswith("opencl.image3d_ro_t") ||
        STy->getName().startswith("opencl.image3d_rw_t") ||
        STy->getName().startswith("opencl.image3d_wo_t") ||
        STy->getName().startswith("ocl_image1d_ro") ||
        STy->getName().startswith("ocl_image1d_rw") ||
        STy->getName().startswith("ocl_image1d_wo") ||
        STy->getName().startswith("ocl_image1d_array_ro") ||
        STy->getName().startswith("ocl_image1d_array_rw") ||
        STy->getName().startswith("ocl_image1d_array_wo") ||
        STy->getName().startswith("ocl_image1d_buffer_ro") ||
        STy->getName().startswith("ocl_image1d_buffer_rw") ||
        STy->getName().startswith("ocl_image1d_buffer_wo") ||
        STy->getName().startswith("ocl_image2d_ro") ||
        STy->getName().startswith("ocl_image2d_rw") ||
        STy->getName().startswith("ocl_image2d_wo") ||
        STy->getName().startswith("ocl_image2d_array_ro") ||
        STy->getName().startswith("ocl_image2d_array_rw") ||
        STy->getName().startswith("ocl_image2d_array_wo") ||
        STy->getName().startswith("ocl_image3d_ro") ||
        STy->getName().startswith("ocl_image3d_rw") ||
        STy->getName().startswith("ocl_image3d_wo")) {
      return true;
    }
  }
  return false;
}

spv::Dim clspv::ImageDimensionality(StructType *STy) {
  if (!STy->isOpaque())
    return spv::DimMax;

  if (IsImageType(STy)) {
    if (STy->getName().contains("image1d_buffer"))
      return spv::DimBuffer;
    if (STy->getName().contains("image1d"))
      return spv::Dim1D;
    if (STy->getName().contains("image2d"))
      return spv::Dim2D;
    if (STy->getName().contains("image3d"))
      return spv::Dim3D;
  }

  return spv::DimMax;
}

uint32_t clspv::ImageNumDimensions(StructType *STy) {
  switch (ImageDimensionality(STy)) {
  case spv::Dim1D:
  case spv::DimBuffer:
    return 1;
  case spv::Dim2D:
    return 2;
  case spv::Dim3D:
    return 3;
  default:
    return 0;
  }
}

bool clspv::IsArrayImageType(StructType *type) {
  if (!type->isOpaque())
    return false;
  if (!IsImageType(type))
    return false;
  if (type->getName().startswith("opencl.image1d_array_ro_t") ||
      type->getName().startswith("opencl.image1d_array_wo_t") ||
      type->getName().startswith("opencl.image1d_array_rw_t") ||
      type->getName().startswith("opencl.image2d_array_ro_t") ||
      type->getName().startswith("opencl.image2d_array_wo_t") ||
      type->getName().startswith("opencl.image2d_array_rw_t") ||
      type->getName().startswith("ocl_image1d_array_ro") ||
      type->getName().startswith("ocl_image1d_array_wo") ||
      type->getName().startswith("ocl_image1d_array_rw") ||
      type->getName().startswith("ocl_image2d_array_ro") ||
      type->getName().startswith("ocl_image2d_array_wo") ||
      type->getName().startswith("ocl_image2d_array_rw")) {
    return true;
  }
  return false;
}

bool clspv::IsSampledImageType(StructType *STy) {
  if (!STy->isOpaque())
    return false;
  if (!IsImageType(STy))
    return false;
  return STy->getName().contains(".sampled");
}

bool clspv::IsStorageImageType(StructType *type) {
  if (!type->isOpaque())
    return false;
  if (!IsImageType(type))
    return false;
  if (type->getName().contains("_wo") ||
      type->getName().contains("_rw")) {
    return true;
  }
  return false;
}

bool clspv::IsFloatImageType(StructType *type) {
  return IsImageType(type) && !IsIntImageType(type) && !IsUintImageType(type);
}

bool clspv::IsIntImageType(StructType *type) {
  if (!type->isOpaque())
    return false;
  if (!IsImageType(type))
    return false;
  if (type->getName().contains(".int"))
    return true;
  return false;
}

bool clspv::IsUintImageType(StructType *type) {
  if (!type->isOpaque())
    return false;
  if (!IsImageType(type))
    return false;
  if (type->getName().contains(".uint"))
    return true;
  return false;
}

bool clspv::PointersAre64Bit(llvm::Module &m) {
  return m.getTargetTriple() == "spir64-unknown-unknown";
}
