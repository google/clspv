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
#include "BitcastUtils.h"
#include "Builtins.h"
#include "Constants.h"
#include "spirv/unified1/spirv.hpp"

#include "clspv/Option.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constant.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/Type.h"

using namespace clspv;
using namespace llvm;

namespace {

Type *InferUserType(User *user, bool &isPointerTy, unsigned operand,
                    Type *&backup_ty, LLVMContext &context,
                    DenseMap<Value *, Type *> *cache, Value *v) {
  auto CacheType = [cache, v](Type *ty) {
    (*cache)[v] = ty;
    return ty;
  };
  if (auto *GEP = dyn_cast<GEPOperator>(user)) {
    return GEP->getSourceElementType();
  } else if (auto *load = dyn_cast<LoadInst>(user)) {
    if (!load->getType()->isPointerTy()) {
      return load->getType();
    }
    isPointerTy = true;
  } else if (auto *store = dyn_cast<StoreInst>(user)) {
    if (!store->getValueOperand()->getType()->isPointerTy()) {
      return store->getValueOperand()->getType();
    } else if (!isa<ConstantPointerNull>(store->getValueOperand())) {
      isPointerTy = true;
    }
  } else if (auto *rmw = dyn_cast<AtomicRMWInst>(user)) {
    return rmw->getValOperand()->getType();
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
    switch (info.getType()) {
    case clspv::Builtins::kAtomicInit:
    case clspv::Builtins::kAtomicStore:
    case clspv::Builtins::kAtomicStoreExplicit: {
      // Data type is inferred from the "value" or "desired" operand.
      auto *data_param = call->getArgOperand(1);
      return data_param->getType();
    }
    case clspv::Builtins::kAtomicCompareExchangeStrong:
    case clspv::Builtins::kAtomicCompareExchangeStrongExplicit:
    case clspv::Builtins::kAtomicCompareExchangeWeak:
    case clspv::Builtins::kAtomicCompareExchangeWeakExplicit: {
      // Data type inferred from "desired" operand.
      auto *data_param = call->getArgOperand(2);
      return data_param->getType();
    }
    case clspv::Builtins::kVload:
      // Data type is the scalar return type.
      return call->getType()->getScalarType();
    case clspv::Builtins::kVloadHalf:
    case clspv::Builtins::kVloadaHalf:
      return Type::getHalfTy(context);
    case clspv::Builtins::kVstore: {
      // Data type is the scalar version of the "data" operand.
      auto *data_param = call->getArgOperand(0);
      return data_param->getType()->getScalarType();
    }
    case clspv::Builtins::kVstoreHalf:
    case clspv::Builtins::kVstoreaHalf:
      return Type::getHalfTy(context);
    case clspv::Builtins::kSincos:
    case clspv::Builtins::kModf:
    case clspv::Builtins::kFract:
      // Data type is the same as the return type.
      return call->getType();
    case clspv::Builtins::kFrexp:
    case clspv::Builtins::kRemquo:
    case clspv::Builtins::kLgammaR: {
      // Data type is an i32 equivalent of the return type.
      // That is, same number of components.
      auto *int32Ty = Type::getIntNTy(context, 32);
      auto *data_ty = call->getType();
      if (auto vec_ty = dyn_cast<VectorType>(data_ty))
        return VectorType::get(int32Ty, vec_ty);
      else
        return int32Ty;
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
        return call->getType();
      case spv::Op::OpAtomicStore:
        // Data type is operand 4.
        return call->getArgOperand(4)->getType();
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
          return ty;
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
        return struct_ty;
      } else if (BUILTIN_IN_GROUP(info.getType(), Atomic) ||
                 info.getType() == clspv::Builtins::kSpirvAtomicXor) {
        // TODO: handle atomic flag functions properly.
        // Data type is the same as the return type.
        return call->getType();
      } else if (BUILTIN_IN_GROUP(info.getType(), Async)) {
        // Data type is inferred through the mangling of the operand.
        auto param = info.getParameter(operand);
        return param.DataType(context);
      }
      break;
    }
  }
  return nullptr;
}

// Returns the type of the member in the given struct with the smallest bit
// representation. Returns nullptr if the given type is not a struct, or has no
// members.
Type *ExtractSmallerStructField(const DataLayout &DL, Type *Ty) {
  auto *STy = dyn_cast<StructType>(Ty);
  if (!STy || STy->getNumElements() == 0)
    return nullptr;
  Type *Smaller = STy->getElementType(0);
  for (unsigned i = 1; i < STy->getNumElements(); i++) {
    Type *Field = STy->getElementType(i);
    if (BitcastUtils::SizeInBits(DL, Field) <
        BitcastUtils::SizeInBits(DL, Smaller)) {
      Smaller = Field;
    }
  }
  return Smaller;
}

// Returns a preferred type chosen from two types.
// In particular:
// - If either is nullptr, return the other.
// - When one is an aggregate or vector whose first nested member at some
//   level of nesting "matches" the other, then return the aggregate or vector.
//   They both have the same machine byte address, but we prefer the larger
//   type.  Here two types "match" if they're the same, or if they are
//   scalar numeric types (integer or float with the same bit size.
// - If one type is a struct and is larger than the other type, but its
//   smallest member is smaller than the other type, then return
//   that member.
// - Otherwise, if one type is smaller than the other, return the smaller one.
// - When the sizes are the same, prefer the packed structure, if it exists.
Type *SmallerTypeNotAliasing(const DataLayout &DL, Type *TyA, Type *TyB) {
  if (TyA == nullptr) {
    return TyB;
  } else if (TyB == nullptr) {
    return TyA;
  }

  {
    // Check if the types are the same, or if one type is nested in the other
    // and would have the same machine address.
    int Steps;         // not used
    bool PerfectMatch; // not used
    if (BitcastUtils::FindAliasingContainedType(TyA, TyB, Steps, PerfectMatch,
                                                DL, true)) {
      // Prefer the composite type (or the same);
      return TyA;
    }
    if (BitcastUtils::FindAliasingContainedType(TyB, TyA, Steps, PerfectMatch,
                                                DL, true)) {
      // Prefer the composite type.
      return TyB;
    }
  }

  // Handle more cases where TyA != TyB

  if (BitcastUtils::SizeInBits(DL, TyA) > BitcastUtils::SizeInBits(DL, TyB)) {
    if (auto Ty = ExtractSmallerStructField(DL, TyA)) {
      if (BitcastUtils::SizeInBits(DL, Ty) <
          BitcastUtils::SizeInBits(DL, TyB)) {
        // TyA is a struct whose smallest member is smaller than TyB.
        // Return the type of that smallest member.
        return Ty;
      }
    }
    // Prefer the smaller.
    return TyB;
  } else if (BitcastUtils::SizeInBits(DL, TyA) <
             BitcastUtils::SizeInBits(DL, TyB)) {
    if (auto Ty = ExtractSmallerStructField(DL, TyB)) {
      if (BitcastUtils::SizeInBits(DL, Ty) <
          BitcastUtils::SizeInBits(DL, TyA)) {
        // TyB is a struct whose smallest member is smaller than TyA.
        // Return the type of that smallest member.
        return Ty;
      }
    }
    // Prefer the smaller.
    return TyA;
  }

  // TyA size == TyB size
  if (auto STy = dyn_cast<StructType>(TyB)) {
    // If we need to make the choice between 2 packed struct, we need to choose
    // the one created by the RewritePackedStructPass.
    // Just look if TyB is a typical RewritePackedStruct type, if not let's take
    // TyA, which might be the one, or something else.
    if (STy->isPacked() && STy->getNumElements() == 1) {
      if (auto ArrTy = dyn_cast<ArrayType>(STy->getStructElementType(0))) {
        if (ArrTy->getArrayElementType() ==
            Type::getInt8Ty(TyB->getContext())) {
          return TyB;
        }
      }
    }
  }

  return TyA;
}

// Returns the type of |v| inferred by inspecting its users.
// Updates |cache|.
Type *InferUsersType(Value *v, LLVMContext &context,
                     DenseMap<Value *, Type *> *cache) {
  std::vector<std::pair<User *, unsigned>> worklist;
  for (auto &use : v->uses()) {
    worklist.push_back(std::make_pair(use.getUser(), use.getOperandNo()));
  }

  Type *backup_ty = nullptr;
  Type *user_ty = nullptr;
  DenseSet<Value *> seen;
  while (!worklist.empty()) {
    User *user = worklist.back().first;
    unsigned operand = worklist.back().second;
    worklist.pop_back();
    bool isPointerTy = false;
    if (!seen.insert(user).second) {
      continue;
    }

    Instruction *userI = dyn_cast<Instruction>(user);
    if (!userI) {
      continue;
    }
    const DataLayout &DL =
        userI->getParent()->getParent()->getParent()->getDataLayout();

    Type *user_backup_ty = nullptr;
    Type *ty = InferUserType(user, isPointerTy, operand, user_backup_ty,
                             context, cache, v);
    user_ty = SmallerTypeNotAliasing(DL, user_ty, ty);
    if (user_ty == nullptr) {
      backup_ty = SmallerTypeNotAliasing(DL, backup_ty, user_backup_ty);
    }

    // If the result is also a pointer, try to infer from further uses.
    if (user_ty == nullptr && (user->getType()->isPointerTy() || isPointerTy)) {
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
  if (user_ty) {
    return user_ty;
  } else if (backup_ty) {
    return backup_ty;
  }
  return nullptr;
}

} // namespace

Type *clspv::InferType(Value *v, LLVMContext &context,
                       DenseMap<Value *, Type *> *cache) {
  // Non-pointer types are reflexive.
  if (!isa<PointerType>(v->getType()))
    return v->getType();

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
    return CacheType(alloca->getAllocatedType());
  } else if (auto *gv = dyn_cast<GlobalVariable>(v)) {
    return CacheType(gv->getValueType());
  } else if (auto *func = dyn_cast<Function>(v)) {
    return CacheType(func->getFunctionType());
  } else if (auto *select = dyn_cast<SelectInst>(v)) {
    const DataLayout &DL = select->getModule()->getDataLayout();
    auto false_ty = InferType(select->getFalseValue(), context, cache);
    auto true_ty = InferType(select->getTrueValue(), context, cache);
    return CacheType(SmallerTypeNotAliasing(DL, false_ty, true_ty));
  }

  // Special resource-related functions. The last parameter of each function
  // has a placeholder value of the inferred type.
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

  auto users_ty = InferUsersType(v, context, cache);

  // For phis, consider the incoming values in addition to the users
  // of the result.
  if (auto *phi = dyn_cast<PHINode>(v)) {
    Type *phi_ty = users_ty;
    const DataLayout &DL = phi->getModule()->getDataLayout();
    for (unsigned twice = 0; twice < 2; twice++) {
      for (unsigned i = 0; i < phi->getNumIncomingValues(); i++) {
        (*cache)[phi] = phi_ty;
        auto IncValTy = InferType(phi->getIncomingValue(i), context, cache);
        phi_ty = SmallerTypeNotAliasing(DL, phi_ty, IncValTy);
      }
    }
    cache->erase(phi);
    if (phi_ty != nullptr) {
      return CacheType(phi_ty);
    }
  } else if (users_ty) {
    return CacheType(users_ty);
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
        assert(type_name_str.ends_with("*") &&
               "Only expect pointer types here");
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
  }
  return false;
}

bool clspv::IsImageType(Type *type) {
  if (!type)
    return false;

  if (auto *ext_ty = dyn_cast<TargetExtType>(type)) {
    if (ext_ty->getName() == "spirv.Image")
      return true;
  }
  return false;
}

bool clspv::IsSampledImageType(Type *type) {
  if (!IsImageType(type))
    return false;

  if (auto *ext_ty = dyn_cast<TargetExtType>(type)) {
    return ext_ty->getIntParameter(SpvImageTypeOperand::kAccessQualifier) == 0;
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
  }
  return true;
}

spv::Dim clspv::ImageDimensionality(Type *type) {
  if (!IsImageType(type))
    return spv::DimMax;

  if (auto *ext_ty = dyn_cast<TargetExtType>(type)) {
    return static_cast<spv::Dim>(
        ext_ty->getIntParameter(clspv::SpvImageTypeOperand::kDim));
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
  }

  return false;
}

bool clspv::IsWriteOnlyImageType(llvm::Type *type) {
  if (!IsImageType(type))
    return false;

  if (auto *ext_ty = dyn_cast<TargetExtType>(type)) {
    return ext_ty->getIntParameter(
               clspv::SpvImageTypeOperand::kAccessQualifier) == 1;
  }

  return false;
}

Constant *clspv::GetPlaceholderValue(Type *type) {
  if (auto *targetExtTy = dyn_cast<TargetExtType>(type)) {
    if (!targetExtTy->hasProperty(TargetExtType::HasZeroInit)) {
      return UndefValue::get(targetExtTy);
    }
  }
  return Constant::getNullValue(type);
}
