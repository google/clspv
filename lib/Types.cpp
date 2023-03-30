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

#include "clspv/Option.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Metadata.h"
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
  } else if (auto *func = dyn_cast<Function>(v)) {
    return CacheType(func->getFunctionType());
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

  Type *backup_ty = nullptr;
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
    } else if (auto *rmw = dyn_cast<AtomicRMWInst>(user)) {
      return CacheType(rmw->getValOperand()->getType());
    } else if (auto *memcpy = dyn_cast<MemCpyInst>(user)) {
      auto other_op = operand == 0 ? 1 : 0;
      // See if the type can be inferred from the other pointer operand as a
      // last resort.
      // Cache a nullptr to avoid infinite recursion.
      CacheType(nullptr);
      if (auto other_ty =
              InferType(memcpy->getArgOperand(other_op), context, cache)) {
        backup_ty = other_ty;
      }
    } else if (auto *select = dyn_cast<SelectInst>(user)) {
      isPointerTy = true;

      // See if the type can be inferred from the other pointer operand as a
      // last resort.
      // Cache a nullptr to avoid infinite recursion.
      auto other_op = operand == 1 ? 2 : 1;
      CacheType(nullptr);
      if (auto other_ty =
              InferType(select->getOperand(other_op), context, cache)) {
        backup_ty = other_ty;
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
      case clspv::Builtins::kSpirvOp: {
        auto *op_param = call->getArgOperand(0);
        auto op =
            static_cast<spv::Op>(cast<ConstantInt>(op_param)->getZExtValue());
        switch (op) {
        case spv::Op::OpAtomicIAdd:
        case spv::Op::OpAtomicISub:
        case spv::Op::OpAtomicSMin:
        case spv::Op::OpAtomicUMin:
        case spv::Op::OpAtomicSMax:
        case spv::Op::OpAtomicUMax:
        case spv::Op::OpAtomicAnd:
        case spv::Op::OpAtomicOr:
        case spv::Op::OpAtomicXor:
        case spv::Op::OpAtomicIIncrement:
        case spv::Op::OpAtomicIDecrement:
        case spv::Op::OpAtomicCompareExchange:
        case spv::Op::OpAtomicLoad:
        case spv::Op::OpAtomicExchange:
          // Data type is return type.
          return CacheType(call->getType());
        case spv::Op::OpAtomicStore:
          // Data type is operand 4.
          return CacheType(call->getArgOperand(4)->getType());
        default:
          // No other current uses of SPIRVOp deal with pointers, but this
          // code should be expanded if any are added.
          break;
        }
        break;
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
  if (backup_ty) {
    return CacheType(backup_ty);
  }

  // If we have not figured out the type yet and the value is a kernel function
  // argument, deduce it from the arg info metadata if enabled.
  if (clspv::Option::KernelArgInfo() && isa<Argument>(v)) {
    auto arg = cast<Argument>(v);
    auto kernelFn = arg->getParent();
    if (kernelFn->getCallingConv() == CallingConv::SPIR_KERNEL) {
      unsigned ordinal = arg->getArgNo();
      // If ClusterPodKernelArgumentsPass has transformed the kernel signature
      // we need to refer to the argument map to know the index of arguments
      // prior to remapping. The kernel arg info metadata is using the orignal
      // argument indexing.
      const auto *arg_map =
          kernelFn->getMetadata(clspv::KernelArgMapMetadataName());
      if (arg_map) {
        for (const auto &arg : arg_map->operands()) {
          const MDNode *arg_node = dyn_cast<MDNode>(arg.get());
          // Remapped argument index
          const auto new_index =
              mdconst::dyn_extract<ConstantInt>(arg_node->getOperand(2))
                  ->getZExtValue();
          if (new_index != ordinal) {
            continue;
          }
          const auto old_index =
              mdconst::dyn_extract<ConstantInt>(arg_node->getOperand(1))
                  ->getZExtValue();
          ordinal = old_index;
          break;
        }
      }

      assert(kernelFn->getMetadata("kernel_arg_type") &&
             kernelFn->getMetadata("kernel_arg_access_qual"));
      auto const &type_op =
          kernelFn->getMetadata("kernel_arg_type")->getOperand(ordinal);
      auto const &type_name_str = dyn_cast<MDString>(type_op)->getString();

      auto const &access_qual_op =
          kernelFn->getMetadata("kernel_arg_access_qual")->getOperand(ordinal);
      auto const &access_qual_str =
          dyn_cast<MDString>(access_qual_op)->getString();

      if (access_qual_str == "none") {
        assert(type_name_str.endswith("*") && "Only expect pointer types here");
        auto type_name = type_name_str.drop_back(1);
        Type *base_ty = nullptr;
        if (type_name.consume_front("char") ||
            type_name.consume_front("uchar")) {
          base_ty = IntegerType::get(context, 8);
        } else if (type_name.consume_front("short") ||
                   type_name.consume_front("ushort")) {
          base_ty = IntegerType::get(context, 16);
        } else if (type_name.consume_front("int") ||
                   type_name.consume_front("uint")) {
          base_ty = IntegerType::get(context, 32);
        } else if (type_name.consume_front("long") ||
                   type_name.consume_front("ulong")) {
          base_ty = IntegerType::get(context, 64);
        } else if (type_name.consume_front("half")) {
          base_ty = Type::getHalfTy(context);
        } else if (type_name.consume_front("float")) {
          base_ty = Type::getFloatTy(context);
        } else if (type_name.consume_front("double")) {
          base_ty = Type::getDoubleTy(context);
          // Default to int for all types we don't know
        } else {
          return CacheType(IntegerType::get(context, 32));
        }

        if (type_name.size() == 0) {
          return CacheType(base_ty);
        }

        uint32_t numComponents;
        if (type_name.getAsInteger(10, numComponents) == false) {
          // If the long vector pass is enabled, it would have rewritten all
          // uses to arrays; return array types for those cases.
          if ((numComponents > 4) && (clspv::Option::LongVectorSupport())) {
            Type *arrty = ArrayType::get(base_ty, numComponents);
            return CacheType(arrty);
          } else {
            Type *vecty = VectorType::get(base_ty, numComponents, false);
            return CacheType(vecty);
          }
        } else {
          // Default to int for all types we don't know
          return CacheType(IntegerType::get(context, 32));
        }
      }
    }
  }
  return nullptr;
}

// TODO(#1036): Remove support for opaque struct OpenCL types.
namespace Deprecated {

bool IsSamplerType(llvm::StructType *STy) {
  if (!STy)
    return false;
  if (STy->isOpaque()) {
    if (STy->getName().equals("opencl.sampler_t") ||
        STy->getName().equals("ocl_sampler")) {
      return true;
    }
  }
  return false;
}

bool IsImageType(llvm::StructType *STy) {
  if (!STy)
    return false;
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

spv::Dim ImageDimensionality(StructType *STy) {
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

bool IsArrayImageType(StructType *type) {
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

bool IsSampledImageType(StructType *STy) {
  if (!STy->isOpaque())
    return false;
  if (!IsImageType(STy))
    return false;
  return STy->getName().contains(".sampled");
}

bool IsStorageImageType(StructType *type) {
  if (!type->isOpaque())
    return false;
  if (!IsImageType(type))
    return false;
  if (type->getName().contains("_wo") || type->getName().contains("_rw")) {
    return true;
  }
  return false;
}

bool IsIntImageType(StructType *type) {
  if (!type->isOpaque())
    return false;
  if (!IsImageType(type))
    return false;
  if (type->getName().contains(".int"))
    return true;
  return false;
}

bool IsUintImageType(StructType *type) {
  if (!type->isOpaque())
    return false;
  if (!IsImageType(type))
    return false;
  if (type->getName().contains(".uint"))
    return true;
  return false;
}

} // namespace Deprecated

bool clspv::PointersAre64Bit(llvm::Module &m) {
  return m.getTargetTriple() == "spir64-unknown-unknown";
}

bool clspv::IsResourceType(Type *type) {
  if (type->isPointerTy())
    return true;
  if (IsSamplerType(type))
    return true;
  if (IsImageType(type))
    return true;
  return false;
}

bool clspv::IsPhysicalSSBOType(Type *type) {
  if (auto ptr_ty = dyn_cast<PointerType>(type)) {
    if (clspv::Option::PhysicalStorageBuffers() &&
        (ptr_ty->getAddressSpace() == clspv::AddressSpace::Global ||
         ptr_ty->getAddressSpace() == clspv::AddressSpace::Constant)) {
      return true;
    }
  }
  return false;
}

bool clspv::IsSamplerType(Type *type) {
  if (!type)
    return false;

  if (auto *ext_ty = dyn_cast<TargetExtType>(type)) {
    if (ext_ty->getName() == "spirv.Sampler")
      return true;
  } else if (auto *struct_ty = dyn_cast<StructType>(type)) {
    return Deprecated::IsSamplerType(struct_ty);
  }
  return false;
}

bool clspv::IsImageType(Type *type) {
  if (!type)
    return false;

  if (auto *ext_ty = dyn_cast<TargetExtType>(type)) {
    if (ext_ty->getName() == "spirv.Image")
      return true;
  } else if (auto *struct_ty = dyn_cast<StructType>(type)) {
    return Deprecated::IsImageType(struct_ty);
  }
  return false;
}

bool clspv::IsSampledImageType(Type *type) {
  if (!IsImageType(type))
    return false;

  if (auto *ext_ty = dyn_cast<TargetExtType>(type)) {
    return ext_ty->getIntParameter(SpvImageTypeOperand::kAccessQualifier) == 0;
  } else if (auto *struct_ty = dyn_cast<StructType>(type)) {
    return Deprecated::IsSampledImageType(struct_ty);
  }
  return true;
}

bool clspv::IsStorageImageType(Type *type) {
  if (!IsImageType(type))
    return false;

  if (auto *ext_ty = dyn_cast<TargetExtType>(type)) {
    const auto access =
        ext_ty->getIntParameter(SpvImageTypeOperand::kAccessQualifier);
    return access == 1 || access == 2;
  } else if (auto *struct_ty = dyn_cast<StructType>(type)) {
    return Deprecated::IsStorageImageType(struct_ty);
  }
  return true;
}

spv::Dim clspv::ImageDimensionality(Type *type) {
  if (!IsImageType(type))
    return spv::DimMax;

  if (auto *ext_ty = dyn_cast<TargetExtType>(type)) {
    return static_cast<spv::Dim>(
        ext_ty->getIntParameter(clspv::SpvImageTypeOperand::kDim));
  } else if (auto *struct_ty = dyn_cast<StructType>(type)) {
    return Deprecated::ImageDimensionality(struct_ty);
  }

  return spv::DimMax;
}

uint32_t clspv::ImageNumDimensions(Type *type) {
  switch (ImageDimensionality(type)) {
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

bool clspv::IsArrayImageType(llvm::Type *type) {
  if (!IsImageType(type))
    return false;

  if (auto *ext_ty = dyn_cast<TargetExtType>(type)) {
    return ext_ty->getIntParameter(clspv::SpvImageTypeOperand::kArrayed) == 1;
  } else if (auto *struct_ty = dyn_cast<StructType>(type)) {
    return Deprecated::IsArrayImageType(struct_ty);
  }
  return false;
}

bool clspv::IsFloatImageType(llvm::Type *type) {
  return IsImageType(type) && !IsIntImageType(type) && !IsUintImageType(type);
}

bool clspv::IsIntImageType(llvm::Type *type) {
  if (!IsImageType(type))
    return false;

  if (auto *ext_ty = dyn_cast<TargetExtType>(type)) {
    const bool int_sampled = ext_ty->getTypeParameter(0)->isIntegerTy(32);
    const bool uint = ext_ty->getNumIntParameters() >
                              clspv::SpvImageTypeOperand::kClspvUnsigned
                          ? ext_ty->getIntParameter(
                                clspv::SpvImageTypeOperand::kClspvUnsigned) == 1
                          : false;
    return int_sampled && !uint;
  } else if (auto *struct_ty = dyn_cast<StructType>(type)) {
    return Deprecated::IsIntImageType(struct_ty);
  }

  return false;
}

bool clspv::IsUintImageType(llvm::Type *type) {
  if (!IsImageType(type))
    return false;

  if (auto *ext_ty = dyn_cast<TargetExtType>(type)) {
    const bool int_sampled = ext_ty->getTypeParameter(0)->isIntegerTy(32);
    const bool uint = ext_ty->getNumIntParameters() >
                              clspv::SpvImageTypeOperand::kClspvUnsigned
                          ? ext_ty->getIntParameter(
                                clspv::SpvImageTypeOperand::kClspvUnsigned) == 1
                          : false;
    return int_sampled && uint;
  } else if (auto *struct_ty = dyn_cast<StructType>(type)) {
    return Deprecated::IsUintImageType(struct_ty);
  }

  return false;
}

bool clspv::IsWriteOnlyImageType(llvm::Type *type) {
  if (!IsImageType(type))
    return false;

  if (auto *ext_ty = dyn_cast<TargetExtType>(type)) {
    return ext_ty->getIntParameter(
               clspv::SpvImageTypeOperand::kAccessQualifier) == 1;
  } else if (auto *struct_ty = dyn_cast<StructType>(type)) {
    return struct_ty->getName().contains("_wo");
  }

  return false;
}
