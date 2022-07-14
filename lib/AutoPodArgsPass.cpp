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

#include "llvm/IR/CallingConv.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/MathExtras.h"

#include "spirv/unified1/spirv.hpp"

#include "clspv/Option.h"

#include "ArgKind.h"
#include "AutoPodArgsPass.h"
#include "Constants.h"
#include "Layout.h"
#include "PushConstant.h"

using namespace llvm;

PreservedAnalyses clspv::AutoPodArgsPass::run(Module &M,
                                              ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  if (clspv::Option::PodArgsInUniformBuffer()) {
    AnnotateAllKernels(M, clspv::PodArgImpl::kUBO);
    return PA;
  } else if (clspv::Option::PodArgsInPushConstants()) {
    AnnotateAllKernels(M, clspv::PodArgImpl::kPushConstant);
    return PA;
  }

  for (auto &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL)
      continue;

    runOnFunction(F);
  }

  return PA;
}

namespace {
bool FunctionContainsImageChannelGetter(Function *F) {
  std::set<Function *> visited_fct;
  SmallVector<Function *, 1> fcts_to_visit;
  SmallVector<Function *, 1> next_fcts_to_visit;
  fcts_to_visit.push_back(F);
  while (!fcts_to_visit.empty()) {
    for (auto *fct : fcts_to_visit) {
      visited_fct.insert(fct);
      for (auto &BB : *fct) {
        for (auto &I : BB) {
          if (auto call = dyn_cast<CallInst>(&I)) {
            auto Name = call->getCalledFunction()->getName();
            if (Name.contains("get_image_channel_order") ||
                Name.contains("get_image_channel_data_type")) {
              return true;
            } else {
              Function *f = call->getCalledFunction();
              if (visited_fct.count(f) == 0) {
                next_fcts_to_visit.push_back(f);
              }
            }
          }
        }
      }
    }
    fcts_to_visit = std::move(next_fcts_to_visit);
    next_fcts_to_visit.clear();
  }
  return false;
}
} // namespace

void clspv::AutoPodArgsPass::runOnFunction(Function &F) {
  auto &M = *F.getParent();
  const auto &DL = M.getDataLayout();
  SmallVector<Type *, 8> pod_types;
  bool satisfies_ubo = true;
  for (auto &Arg : F.args()) {
    auto arg_type = Arg.getType();
    if (Arg.hasByValAttr()) {
      // Byval arguments end up as POD arguments.
      arg_type = Arg.getParamByValType();
    }

    if (isa<PointerType>(arg_type))
      continue;

    pod_types.push_back(arg_type);

    // If the type contains an 8- or 16-bit type UBO storage must be supported.
    satisfies_ubo &= !ContainsSizedType(arg_type, 16) ||
                     clspv::Option::Supports16BitStorageClass(
                         clspv::Option::StorageClass::kUBO);
    satisfies_ubo &= !ContainsSizedType(arg_type, 8) ||
                     clspv::Option::Supports8BitStorageClass(
                         clspv::Option::StorageClass::kUBO);
    if (auto struct_ty = dyn_cast<StructType>(arg_type)) {
      // Only check individual arguments as clustering will fix the layout with
      // padding if necessary.
      satisfies_ubo &=
          clspv::isValidExplicitLayout(M, struct_ty, spv::StorageClassUniform);
    }
  }
  const bool contains_image_channel_getter = FunctionContainsImageChannelGetter(&F);

  // Per-kernel push constant interface requires:
  // 1. Clustered pod args.
  // 2. No global push constants.
  // 3. Args must fit in push constant size limit.
  // 4. No arrays.
  // 5. If 16-bit types are used, 16-bit push constants are supported.
  // 6. If 8-bit types are used, 8-bit push constants are supported.
  // 7. Not to have a image channel getter function call.
  const auto pod_struct_ty = StructType::get(M.getContext(), pod_types);
  const bool contains_array = ContainsArrayType(pod_struct_ty);
  const bool support_16bit_pc = !ContainsSizedType(pod_struct_ty, 16) ||
                                clspv::Option::Supports16BitStorageClass(
                                    clspv::Option::StorageClass::kPushConstant);
  const bool support_8bit_pc = !ContainsSizedType(pod_struct_ty, 8) ||
                               clspv::Option::Supports8BitStorageClass(
                                   clspv::Option::StorageClass::kPushConstant);
  // Align to 4 to use i32s.
  const uint64_t pod_struct_size =
      alignTo(DL.getTypeStoreSize(pod_struct_ty).getKnownMinSize(), 4);
  const bool fits_push_constant =
      pod_struct_size <= clspv::Option::MaxPushConstantsSize();
  const bool satisfies_push_constant =
      clspv::Option::ClusterPodKernelArgs() && support_16bit_pc &&
      support_8bit_pc && fits_push_constant &&
      !clspv::UsesGlobalPushConstants(M) && !contains_array &&
      !contains_image_channel_getter;

  // Global type-mangled push constants require:
  // 1. Clustered pod args.
  // 2. Args and global push constants must fit size limit.
  // 3. Size / 4 must be less than max struct members.
  //    (In order to satisfy SPIR-V limit).
  //
  // Note: There is a potential tradeoff in representations. We could use
  // either a packed or unpacked struct. A packed struct would allow more
  // arguments to fit in the size limit, but potentially results in more
  // instructions to undo the type-mangling. Currently we opt for an unpacked
  // struct for two reasons:
  // 1. The offsets of individual members make more sense at a higher level and
  //    are consistent with other clustered implementations.
  // 2. The type demangling code is simpler (but may result in wasted space).
  //
  // TODO: We should generate a better pod struct by default (e.g. { i32, i8 }
  // is preferable to { i8, i32 }). Also we could support packed structs as
  // fallback to fit arguments depending on the performance cost.
  const auto global_size = clspv::GlobalPushConstantsSize(M) + pod_struct_size;
  const auto fits_global_size =
      global_size <= clspv::Option::MaxPushConstantsSize();
  // Leave some extra room for other push constants.
  const uint64_t max_struct_members = 0x3fff - 64;
  const auto enough_members = (global_size / 4) < max_struct_members;
  const bool satisfies_global_push_constant =
      clspv::Option::ClusterPodKernelArgs() && fits_global_size &&
      enough_members;

  // Priority:
  // 1. Per-kernel push constant interface.
  // 2. Global type mangled push constant interface.
  // 3. UBO
  // 4. SSBO
  clspv::PodArgImpl impl = clspv::PodArgImpl::kSSBO;
  if (satisfies_push_constant) {
    impl = clspv::PodArgImpl::kPushConstant;
  } else if (satisfies_global_push_constant) {
    impl = clspv::PodArgImpl::kGlobalPushConstant;
  } else if (satisfies_ubo) {
    impl = clspv::PodArgImpl::kUBO;
  }
  AddMetadata(F, impl);
}

void clspv::AutoPodArgsPass::AnnotateAllKernels(Module &M,
                                                clspv::PodArgImpl impl) {
  for (auto &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL)
      continue;

    AddMetadata(F, impl);
  }
}

void clspv::AutoPodArgsPass::AddMetadata(Function &F, clspv::PodArgImpl impl) {
  auto md = MDTuple::get(
      F.getContext(),
      ConstantAsMetadata::get(ConstantInt::get(
          IntegerType::get(F.getContext(), 32), static_cast<uint32_t>(impl))));
  F.setMetadata(clspv::PodArgsImplMetadataName(), md);
}

bool clspv::AutoPodArgsPass::ContainsArrayType(Type *type) const {
  if (isa<ArrayType>(type)) {
    return true;
  } else if (auto struct_ty = dyn_cast<StructType>(type)) {
    for (auto sub_type : struct_ty->elements()) {
      if (ContainsArrayType(sub_type))
        return true;
    }
  }

  return false;
}

bool clspv::AutoPodArgsPass::ContainsSizedType(Type *type,
                                               uint32_t width) const {
  if (auto int_ty = dyn_cast<IntegerType>(type)) {
    return int_ty->getBitWidth() == width;
  } else if (type->isHalfTy()) {
    return width == 16;
  } else if (auto array_ty = dyn_cast<ArrayType>(type)) {
    return ContainsSizedType(array_ty->getElementType(), width);
  } else if (auto vec_ty = dyn_cast<VectorType>(type)) {
    return ContainsSizedType(vec_ty->getElementType(), width);
  } else if (auto struct_ty = dyn_cast<StructType>(type)) {
    for (auto sub_type : struct_ty->elements()) {
      if (ContainsSizedType(sub_type, width))
        return true;
    }
  }

  return false;
}
