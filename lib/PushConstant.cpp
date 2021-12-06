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
         ShouldDeclareRegionGroupOffsetPushConstant(M);
}

bool ShouldDeclareGlobalOffsetPushConstant(Module &M) {
  bool isEnabled = (clspv::Option::GlobalOffset() &&
                    clspv::Option::NonUniformNDRangeSupported()) ||
                   clspv::Option::GlobalOffsetPushConstant();
  bool isUsed = (M.getFunction("_Z17get_global_offsetj") != nullptr) ||
                (M.getFunction("_Z13get_global_idj") != nullptr);
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
  bool isUsed = M.getFunction("_Z15get_global_sizej") != nullptr;
  return isEnabled && isUsed;
}

bool ShouldDeclareRegionOffsetPushConstant(Module &M) {
  bool isEnabled = clspv::Option::NonUniformNDRangeSupported();
  bool isUsed = M.getFunction("_Z13get_global_idj") != nullptr;
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

uint64_t GlobalPushConstantsSize(Module &M) {
  const auto &DL = M.getDataLayout();
  if (auto GV = M.getGlobalVariable(clspv::PushConstantsVariableName())) {
    auto ptr_ty = GV->getType();
    auto block_ty = ptr_ty->getPointerElementType();
    return DL.getTypeStoreSize(block_ty).getKnownMinSize();
  } else {
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

    auto block_ty = StructType::get(M.getContext(), types, false);
    return DL.getTypeStoreSize(block_ty).getKnownMinSize();
  }
}

} // namespace clspv
