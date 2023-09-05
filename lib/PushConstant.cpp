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

#include "PushConstant.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/ErrorHandling.h"

#include "clspv/Option.h"

#include "BitcastUtils.h"
#include "Constants.h"

using namespace llvm;

namespace clspv {

const char *GetPushConstantName(PushConstant pc) {
  switch (pc) {
  case PushConstant::Dimensions:
    return "dimensions";
  case PushConstant::GlobalOffset:
    return "global_offset";
  case PushConstant::EnqueuedLocalSize:
    return "enqueued_local_size";
  case PushConstant::GlobalSize:
    return "global_size";
  case PushConstant::RegionOffset:
    return "region_offset";
  case PushConstant::NumWorkgroups:
    return "num_workgroups";
  case PushConstant::RegionGroupOffset:
    return "region_group_offset";
  case PushConstant::KernelArgument:
    return "kernel_argument";
  case PushConstant::ImageMetadata:
    return "image_metadata";
  case PushConstant::ModuleConstantsPointer:
    return "module_constants_pointer";
  case PushConstant::PrintfBufferPointer:
    return "printf_buffer_pointer";
  }
  llvm_unreachable("Unknown PushConstant in GetPushConstantName");
  return "";
}

Type *GetPushConstantType(Module &M, PushConstant pc) {
  auto &C = M.getContext();
  switch (pc) {
  case PushConstant::Dimensions:
    return IntegerType::get(C, 32);
  case PushConstant::GlobalOffset:
    return FixedVectorType::get(IntegerType::get(C, 32), 3);
  case PushConstant::EnqueuedLocalSize:
    return FixedVectorType::get(IntegerType::get(C, 32), 3);
  case PushConstant::GlobalSize:
    return FixedVectorType::get(IntegerType::get(C, 32), 3);
  case PushConstant::RegionOffset:
    return FixedVectorType::get(IntegerType::get(C, 32), 3);
  case PushConstant::NumWorkgroups:
    return FixedVectorType::get(IntegerType::get(C, 32), 3);
  case PushConstant::RegionGroupOffset:
    return FixedVectorType::get(IntegerType::get(C, 32), 3);
  case PushConstant::ImageMetadata:
    return IntegerType::get(C, 32);
  case PushConstant::ModuleConstantsPointer:
    return IntegerType::get(C, 64);
  case PushConstant::PrintfBufferPointer:
    return IntegerType::get(C, 64);
  default:
    break;
  }
  llvm_unreachable("Unknown PushConstant in GetPushConstantType");
  return nullptr;
}

Value *GetPushConstantPointer(BasicBlock *BB, PushConstant pc,
                              const ArrayRef<Value *> &extra_indices) {
  auto M = BB->getParent()->getParent();

  // Get variable
  auto GV = M->getGlobalVariable(clspv::PushConstantsVariableName());
  assert(GV && "Push constants requested but none are declared.");

  // Find requested pc in metadata
  auto MD = GV->getMetadata(clspv::PushConstantsMetadataName());
#ifndef NDEBUG
  bool found = false;
#endif
  uint32_t idx = 0;
  for (auto &PCMD : MD->operands()) {
    auto mpc = static_cast<PushConstant>(
        mdconst::extract<ConstantInt>(PCMD)->getZExtValue());
    if (mpc == pc) {
#ifndef NDEBUG
      found = true;
#endif
      break;
    }
    idx++;
  }

  // Assert that it exists
  assert(found && "Push constant wasn't declared.");

  // Construct pointer
  IRBuilder<> Builder(BB);
  SmallVector<Value *, 4> Indices(2);
  Indices[0] = Builder.getInt32(0);
  Indices[1] = Builder.getInt32(idx);
  for (auto idx : extra_indices)
    Indices.push_back(idx);
  return Builder.CreateInBoundsGEP(GV->getValueType(), GV, Indices);
}

bool UsesGlobalPushConstants(Module &M) {
  return ShouldDeclareGlobalOffsetPushConstant(M) ||
         ShouldDeclareEnqueuedLocalSizePushConstant(M) ||
         ShouldDeclareGlobalSizePushConstant(M) ||
         ShouldDeclareRegionOffsetPushConstant(M) ||
         ShouldDeclareNumWorkgroupsPushConstant(M) ||
         ShouldDeclareRegionGroupOffsetPushConstant(M) ||
         ShouldDeclareModuleConstantsPointerPushConstant(M) ||
         ShouldDeclarePrintfBufferPointerPushConstant(M);
}

bool ShouldDeclareGlobalOffsetPushConstant(Module &M) {
  bool isEnabled = (clspv::Option::GlobalOffset() &&
                    clspv::Option::NonUniformNDRangeSupported()) ||
                   clspv::Option::GlobalOffsetPushConstant();
  bool isUsed = (M.getFunction("_Z17get_global_offsetj") != nullptr) ||
                (M.getFunction("_Z13get_global_idj") != nullptr) ||
                (M.getFunction("_Z20get_global_linear_idv") != nullptr);
  return isEnabled && isUsed;
}

bool ShouldDeclareEnqueuedLocalSizePushConstant(Module &M) {
  bool isEnabled = clspv::Option::NonUniformNDRangeSupported();
  bool isUsed = (M.getFunction("_Z23get_enqueued_local_sizej") != nullptr) ||
                (M.getFunction("_Z27get_enqueued_num_sub_groupsv") != nullptr);
  return isEnabled && isUsed;
}

bool ShouldDeclareGlobalSizePushConstant(Module &M) {
  bool isEnabled = clspv::Option::NonUniformNDRangeSupported();
  bool isUsed = M.getFunction("_Z15get_global_sizej") != nullptr ||
                M.getFunction("_Z20get_global_linear_idv") != nullptr;
  return isEnabled && isUsed;
}

bool ShouldDeclareRegionOffsetPushConstant(Module &M) {
  bool isEnabled = clspv::Option::NonUniformNDRangeSupported();
  bool isUsed = M.getFunction("_Z13get_global_idj") != nullptr ||
                M.getFunction("_Z20get_global_linear_idv") != nullptr;
  return isEnabled && isUsed;
}

bool ShouldDeclareNumWorkgroupsPushConstant(Module &M) {
  bool isEnabled = clspv::Option::NonUniformNDRangeSupported();
  bool isUsed = M.getFunction("_Z14get_num_groupsj") != nullptr;
  return isEnabled && isUsed;
}

bool ShouldDeclareRegionGroupOffsetPushConstant(Module &M) {
  bool isEnabled = clspv::Option::NonUniformNDRangeSupported();
  bool isUsed = M.getFunction("_Z12get_group_idj") != nullptr;
  return isEnabled && isUsed;
}

bool ShouldDeclareModuleConstantsPointerPushConstant(Module &M) {
  bool isEnabled = clspv::Option::ModuleConstantsInStorageBuffer() &&
                   clspv::Option::PhysicalStorageBuffers();

  bool moduleHasGlobals = false;
  for (GlobalVariable &GV : M.globals()) {
    if (GV.hasInitializer() && GV.getType()->getPointerAddressSpace() ==
                                   clspv::AddressSpace::Constant) {
      if (!GV.use_empty()) {
        moduleHasGlobals = true;
        break;
      }
    }
  }

  return isEnabled && moduleHasGlobals;
}

bool ShouldDeclarePrintfBufferPointerPushConstant(Module &M) {
  bool isEnabled =
      clspv::Option::PrintfSupport() && clspv::Option::PhysicalStorageBuffers();
  bool isUsed = M.getFunction("printf") != nullptr;
  return isEnabled && isUsed;
}

StructType *GlobalPushConstantsType(Module &M) {
  if (auto GV = M.getGlobalVariable(clspv::PushConstantsVariableName())) {
    if (auto *STy = dyn_cast<StructType>(GV->getValueType())) {
      return STy;
    }
  }
  SmallVector<Type *, 8> types;
  if (ShouldDeclareGlobalOffsetPushConstant(M)) {
    auto type = GetPushConstantType(M, PushConstant::GlobalOffset);
    types.push_back(type);
  }
  if (ShouldDeclareEnqueuedLocalSizePushConstant(M)) {
    auto type = GetPushConstantType(M, PushConstant::EnqueuedLocalSize);
    types.push_back(type);
  }
  if (ShouldDeclareGlobalSizePushConstant(M)) {
    auto type = GetPushConstantType(M, PushConstant::GlobalSize);
    types.push_back(type);
  }
  if (ShouldDeclareRegionOffsetPushConstant(M)) {
    auto type = GetPushConstantType(M, PushConstant::RegionOffset);
    types.push_back(type);
  }
  if (ShouldDeclareNumWorkgroupsPushConstant(M)) {
    auto type = GetPushConstantType(M, PushConstant::NumWorkgroups);
    types.push_back(type);
  }
  if (ShouldDeclareRegionGroupOffsetPushConstant(M)) {
    auto type = GetPushConstantType(M, PushConstant::RegionGroupOffset);
    types.push_back(type);
  }
  if (ShouldDeclareModuleConstantsPointerPushConstant(M)) {
    auto type = GetPushConstantType(M, PushConstant::ModuleConstantsPointer);
    types.push_back(type);
  }
  if (ShouldDeclarePrintfBufferPointerPushConstant(M)) {
    auto type = GetPushConstantType(M, PushConstant::PrintfBufferPointer);
    types.push_back(type);
  }

  return StructType::get(M.getContext(), types, false);
}

const uint64_t kIntBytes = 4;

void RedeclareGlobalPushConstants(Module &M, StructType *mangled_struct_ty,
                                  int push_constant_type) {
  auto old_GV = M.getGlobalVariable(clspv::PushConstantsVariableName());

  std::vector<Type *> push_constant_tys;
  if (old_GV) {
    auto block_ty = cast<StructType>(old_GV->getValueType());
    for (auto ele : block_ty->elements())
      push_constant_tys.push_back(ele);
  }
  push_constant_tys.push_back(mangled_struct_ty);

  auto push_constant_ty = StructType::create(M.getContext(), push_constant_tys);
  auto new_GV = new GlobalVariable(
      M, push_constant_ty, false, GlobalValue::ExternalLinkage, nullptr, "",
      nullptr, GlobalValue::ThreadLocalMode::NotThreadLocal,
      clspv::AddressSpace::PushConstant);
  new_GV->setInitializer(Constant::getNullValue(push_constant_ty));
  std::vector<Metadata *> md_args;
  if (old_GV) {
    // Replace the old push constant variable metadata and uses.
    new_GV->takeName(old_GV);
    auto md = old_GV->getMetadata(clspv::PushConstantsMetadataName());
    for (auto &op : md->operands()) {
      md_args.push_back(op.get());
    }
    std::vector<User *> users;
    for (auto user : old_GV->users())
      users.push_back(user);
    for (auto user : users) {
      if (auto gep = dyn_cast<GetElementPtrInst>(user)) {
        // Most uses are likely constant geps, but handle instructions first
        // since we can only really access gep operators for the constant side.
        SmallVector<Value *, 4> indices;
        for (auto iter = gep->idx_begin(); iter != gep->idx_end(); ++iter) {
          indices.push_back(*iter);
        }
        auto new_gep = GetElementPtrInst::Create(push_constant_ty, new_GV,
                                                 indices, "", gep);
        new_gep->setIsInBounds(gep->isInBounds());
        gep->replaceAllUsesWith(new_gep);
        gep->eraseFromParent();
      } else if (auto gep_operator = dyn_cast<GEPOperator>(user)) {
        int steps;
        bool perfect_match;
        bool alias_found = BitcastUtils::FindAliasingContainedType(
            push_constant_ty, gep_operator->getSourceElementType(), steps,
            perfect_match, M.getDataLayout());

        SmallVector<Constant *, 4> indices;
        if (alias_found) {
          for (int i = 0; i < steps; i++) {
            indices.push_back(
                ConstantInt::get(Type::getInt32Ty(M.getContext()), 0));
          }
        }

        for (auto iter = gep_operator->idx_begin();
             iter != gep_operator->idx_end(); ++iter) {
          auto cst = cast<Constant>(*iter);
          if (cst->getType()->isIntegerTy(64) &&
              GetElementPtrInst::getIndexedType(push_constant_ty, indices)
                  ->isStructTy()) {
            cst = ConstantInt::get(IntegerType::get(M.getContext(), 32),
                                   cast<ConstantInt>(cst)->getZExtValue());
          }
          indices.push_back(cst);
        }
        auto new_gep = ConstantExpr::getGetElementPtr(
            push_constant_ty, new_GV, indices, gep_operator->isInBounds());
        user->replaceAllUsesWith(new_gep);
      } else if (auto load = dyn_cast<LoadInst>(user)) {
        auto new_load = new LoadInst(load->getType(), new_GV, "", load);
        load->replaceAllUsesWith(new_load);
        load->eraseFromParent();
      } else {
        user->print(errs());
        assert(false && "unexpected global use");
      }
    }
    old_GV->removeDeadConstantUsers();
    old_GV->eraseFromParent();
  } else {
    new_GV->setName(clspv::PushConstantsVariableName());
  }
  // New metadata operand for the kernel arguments.
  auto cst = ConstantInt::get(IntegerType::get(M.getContext(), 32),
                              static_cast<int>(push_constant_type));
  md_args.push_back(ConstantAsMetadata::get(cst));
  new_GV->setMetadata(clspv::PushConstantsMetadataName(),
                      MDNode::get(M.getContext(), md_args));
}

Value *ConvertToType(Module &M, StructType *pod_struct, unsigned index,
                     IRBuilder<> &builder) {
  auto int32_ty = IntegerType::get(M.getContext(), 32);
  const auto &DL = M.getDataLayout();
  const auto struct_layout = DL.getStructLayout(pod_struct);
  auto ele_ty = pod_struct->getElementType(index);
  const auto ele_size = DL.getTypeStoreSize(ele_ty).getKnownMinValue();
  auto ele_offset = struct_layout->getElementOffset(index);
  const auto ele_start_index = ele_offset / kIntBytes; // round down
  const auto ele_end_index =
      (ele_offset + ele_size + kIntBytes - 1) / kIntBytes; // round up

  // Load the right number of ints. We'll load at least one, but may load
  // ele_size / 4 + 1 integers depending on the offset.
  std::vector<Value *> int_elements;
  uint32_t i = ele_start_index;
  do {
    auto gep = clspv::GetPushConstantPointer(
        builder.GetInsertBlock(), clspv::PushConstant::KernelArgument,
        {builder.getInt32(i)});
    auto ld = builder.CreateLoad(int32_ty, gep);
    int_elements.push_back(ld);
    i++;
  } while (i < ele_end_index);

  return BuildFromElements(M, builder, ele_ty, ele_offset % kIntBytes, 0,
                           int_elements);
}

Value *BuildFromElements(Module &M, IRBuilder<> &builder, Type *dst_type,
                         uint64_t base_offset, uint64_t base_index,
                         const std::vector<Value *> &elements) {
  auto int32_ty = IntegerType::get(M.getContext(), 32);
  const auto &DL = M.getDataLayout();
  const auto dst_size = DL.getTypeStoreSize(dst_type).getKnownMinValue();
  auto dst_array_ty = dyn_cast<ArrayType>(dst_type);
  auto dst_vec_ty = dyn_cast<VectorType>(dst_type);

  Value *dst = nullptr;
  if (auto dst_struct_ty = dyn_cast<StructType>(dst_type)) {
    // Create an insertvalue chain for each converted element.
    auto struct_layout = DL.getStructLayout(dst_struct_ty);
    for (uint32_t i = 0; i < dst_struct_ty->getNumElements(); ++i) {
      auto ele_ty = dst_struct_ty->getTypeAtIndex(i);
      const auto ele_offset = struct_layout->getElementOffset(i);
      const auto index = base_index + (ele_offset / kIntBytes);
      const auto offset = (base_offset + ele_offset) % kIntBytes;

      auto tmp = BuildFromElements(M, builder, ele_ty, offset, index, elements);
      dst = builder.CreateInsertValue(dst ? dst : PoisonValue::get(dst_type),
                                      tmp, {i});
    }
  } else if (dst_array_ty || dst_vec_ty) {
    if (dst_vec_ty && dst_vec_ty->getPrimitiveSizeInBits() ==
                          int32_ty->getPrimitiveSizeInBits()) {
      // Easy case is just a bitcast.
      dst = builder.CreateBitCast(elements[base_index], dst_type);
    } else if (dst_vec_ty &&
               dst_vec_ty->getElementType()->getPrimitiveSizeInBits() <
                   int32_ty->getPrimitiveSizeInBits()) {
      // Bitcast integers to a vector of the primitive type and then shuffle
      // elements into the final vector.
      //
      // We need at most two integers to handle any case here.
      auto ele_ty = dst_vec_ty->getElementType();
      uint32_t num_elements = dst_vec_ty->getElementCount().getKnownMinValue();
      uint32_t ratio = (int32_ty->getPrimitiveSizeInBits() /
                        ele_ty->getPrimitiveSizeInBits());
      auto scaled_vec_ty = FixedVectorType::get(ele_ty, ratio);
      SmallVector<Value *, 4> casts;
      uint32_t num_ints = (num_elements + ratio - 1) / ratio;  // round up
      num_ints = std::max(num_ints, 1u);
      for (uint32_t i = 0; i < num_ints; ++i) {
        casts.push_back(
            builder.CreateBitCast(elements[base_index + i], scaled_vec_ty));
      }
      SmallVector<int, 4> indices(num_elements);
      uint32_t i = 0;
      std::generate_n(indices.data(), num_elements, [&i]() { return i++; });
      switch (casts.size()) {
        case 1:
          // The only types that results in 1 cast are char2 and char3.
          dst = builder.CreateShuffleVector(casts[0], indices);
          break;
        case 2:
          dst = builder.CreateShuffleVector(casts[0], casts[1], indices);
          break;
        case 4: {
          SmallVector<int, 4> inter_indices({0, 1, 2, 3});
          // Four casts could be 8 wide, 16-bit ele type or 16 wide 8-bit ele
          // type. We can determine this by looking at the known min width of
          // our cast vectors and setting up shuffle indices according.
          auto vec_size = cast<VectorType>(casts[0]->getType())
                              ->getElementCount()
                              .getKnownMinValue();
          if (vec_size == 4) {
            inter_indices.append({4, 5, 6, 7});
          } else if(vec_size != 2) {
            llvm_unreachable("Impossible cast vector size encountered.");
          }
          auto lo =
              builder.CreateShuffleVector(casts[0], casts[1], inter_indices);
          auto hi =
              builder.CreateShuffleVector(casts[2], casts[3], inter_indices);
          dst = builder.CreateShuffleVector(lo, hi, indices);
          break;
        }
        case 8: {
          // The only case with 8 casts is a vector of 16 width, 16-bit element
          // type. We can reconstruct this by first shuffling them into 2 vec8s
          // and then into the final vec16.
          SmallVector<int, 8> inter_indices = {0, 1, 2, 3};
          auto lo = builder.CreateShuffleVector(casts[0], casts[1], inter_indices);
          auto hi = builder.CreateShuffleVector(casts[2], casts[3], inter_indices);
          auto lo2 = builder.CreateShuffleVector(casts[4], casts[5], inter_indices);
          auto hi2 = builder.CreateShuffleVector(casts[6], casts[7], inter_indices);
          inter_indices.append({4, 5, 6, 7});
          auto lo3 = builder.CreateShuffleVector(lo, hi, inter_indices);
          auto hi3 = builder.CreateShuffleVector(lo2, hi2, inter_indices);
          dst = builder.CreateShuffleVector(lo3, hi3, indices);
        }
      }
    } else {
      // General case, break into elements and construct the composite type.
      auto ele_ty = dst_vec_ty ? dst_vec_ty->getElementType()
                               : dst_array_ty->getElementType();
      assert((DL.getTypeStoreSize(ele_ty).getKnownMinValue() < kIntBytes ||
              base_offset == 0) &&
             "Unexpected packed data format");
      uint64_t ele_size = DL.getTypeStoreSize(ele_ty);
      uint32_t num_elements =
          dst_vec_ty ? dst_vec_ty->getElementCount().getKnownMinValue()
                     : dst_array_ty->getNumElements();

      // Arrays of shorts/halfs could be offset from the start of an int.
      uint64_t bytes_consumed = 0;
      for (uint32_t i = 0; i < num_elements; ++i) {
        uint64_t ele_offset = (base_offset + bytes_consumed) % kIntBytes;
        uint64_t ele_index =
            base_index + (base_offset + bytes_consumed) / kIntBytes;
        // Convert the element.
        auto tmp = BuildFromElements(M, builder, ele_ty, ele_offset, ele_index,
                                     elements);
        if (dst_vec_ty) {
          dst = builder.CreateInsertElement(
              dst ? dst : PoisonValue::get(dst_type), tmp, i);
        } else {
          dst = builder.CreateInsertValue(
              dst ? dst : PoisonValue::get(dst_type), tmp, {i});
        }

        // Track consumed bytes.
        bytes_consumed += ele_size;
      }
    }
  } else {
    // Base case is scalar conversion.
    if (dst_size < kIntBytes) {
      dst = elements[base_index];
      if (dst_type->isIntegerTy() && base_offset == 0) {
        // Can generate a single truncate instruction in this case.
        dst = builder.CreateTrunc(
            dst, IntegerType::get(M.getContext(), dst_size * 8));
      } else {
        // Bitcast to a vector of |dst_type| and extract the right element. This
        // avoids introducing i16 when converting to half.
        uint32_t ratio = (int32_ty->getPrimitiveSizeInBits() /
                          dst_type->getPrimitiveSizeInBits());
        auto vec_ty = FixedVectorType::get(dst_type, ratio);
        dst = builder.CreateBitCast(dst, vec_ty);
        dst = builder.CreateExtractElement(dst, base_offset / dst_size);
      }
    } else if (dst_size == kIntBytes) {
      assert(base_offset == 0 && "Unexpected packed data format");
      // Create a bit cast if necessary.
      dst = elements[base_index];
      if (dst_type != int32_ty) dst = builder.CreateBitCast(dst, dst_type);
    } else {
      assert(base_offset == 0 && "Unexpected packed data format");
      assert(dst_size == kIntBytes * 2 && "Expected 64-bit scalar");
      // Round up to number of integers.
      auto dst_int = IntegerType::get(M.getContext(), dst_size * 8);
      auto zext0 = builder.CreateZExt(elements[base_index], dst_int);
      auto zext1 = builder.CreateZExt(elements[base_index + 1], dst_int);
      auto shl = builder.CreateShl(zext1, 32);
      dst = builder.CreateOr({zext0, shl});
      if (dst_type != dst->getType())
        dst = builder.CreateBitCast(dst, dst_type);
    }
  }

  return dst;
}

} // namespace clspv
