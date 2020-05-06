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

#include "spirv/unified1/spirv.hpp"

#include "clspv/Option.h"

#include "ArgKind.h"
#include "Constants.h"
#include "Layout.h"
#include "Passes.h"
#include "PushConstant.h"

#define DEBUG_TYPE "autopodargs"

using namespace llvm;

namespace {
class AutoPodArgsPass : public ModulePass {
public:
  static char ID;
  AutoPodArgsPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;

private:
  // Decides the pod args implementation for each kernel individually.
  void runOnFunction(Function &F);

  // Makes all kernels use |impl| for pod args.
  void AnnotateAllKernels(Module &M, clspv::PodArgImpl impl);

  // Makes kernel |F| use |impl| as the pod arg implementation.
  void AddMetadata(Function &F, clspv::PodArgImpl impl);

  // Returns true if |type| contains an array. Does not look through pointers
  // since we are dealing with pod args.
  bool ContainsArrayType(Type *type) const;

  // Returns true if |type| contains a 16-bit integer or floating-point type.
  // Does not look through pointer since we are dealing with pod args.
  bool ContainsSizedType(Type *type, uint32_t width) const;
};
} // namespace

char AutoPodArgsPass::ID = 0;
INITIALIZE_PASS(AutoPodArgsPass, "AutoPodArgs",
                "Mark pod arg implementation as metadata on kernels", false,
                false)

namespace clspv {
ModulePass *createAutoPodArgsPass() { return new AutoPodArgsPass(); }
} // namespace clspv

bool AutoPodArgsPass::runOnModule(Module &M) {
  if (clspv::Option::PodArgsInUniformBuffer()) {
    AnnotateAllKernels(M, clspv::PodArgImpl::kUBO);
    return true;
  } else if (clspv::Option::PodArgsInPushConstants()) {
    AnnotateAllKernels(M, clspv::PodArgImpl::kPushConstant);
    return true;
  }

  for (auto &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL)
      continue;

    runOnFunction(F);
  }

  return true;
}

void AutoPodArgsPass::runOnFunction(Function &F) {
  auto &M = *F.getParent();
  const auto &DL = M.getDataLayout();
  SmallVector<Type *, 8> pod_types;
  bool satisfies_ubo = true;
  for (auto &Arg : F.args()) {
    auto arg_type = Arg.getType();
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

  // Per-kernel push constant interface requires:
  // 1. Clustered pod args.
  // 2. No global push constants.
  // 3. Args must fit in push constant size limit.
  // 4. No arrays.
  // 5. If 16-bit types are used, 16-bit push constants are supported.
  // 6. If 8-bit types are used, 8-bit push constants are supported.
  const auto pod_struct_ty = StructType::get(M.getContext(), pod_types);
  const bool contains_array = ContainsArrayType(pod_struct_ty);
  const bool support_16bit_pc = !ContainsSizedType(pod_struct_ty, 16) ||
                                clspv::Option::Supports16BitStorageClass(
                                    clspv::Option::StorageClass::kPushConstant);
  const bool support_8bit_pc = !ContainsSizedType(pod_struct_ty, 8) ||
                               clspv::Option::Supports8BitStorageClass(
                                   clspv::Option::StorageClass::kPushConstant);
  const bool fits_push_constant =
      DL.getTypeSizeInBits(pod_struct_ty).getFixedSize() / 8 <=
      clspv::Option::MaxPushConstantSize();
  const bool satisfies_push_constant =
      clspv::Option::ClusterPodKernelArgs() && support_16bit_pc &&
      support_8bit_pc && fits_push_constant &&
      !clspv::UsesGlobalPushConstants(M) && !contains_array;

  // Priority:
  // 1. Per-kernel push constant interface.
  // 2. NYI: global type mangled push constant interface.
  // 3. UBO
  // 4. SSBO
  clspv::PodArgImpl impl = clspv::PodArgImpl::kSSBO;
  if (satisfies_push_constant) {
    impl = clspv::PodArgImpl::kPushConstant;
  } else if (satisfies_ubo) {
    impl = clspv::PodArgImpl::kUBO;
  }
  AddMetadata(F, impl);
}

void AutoPodArgsPass::AnnotateAllKernels(Module &M, clspv::PodArgImpl impl) {
  for (auto &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL)
      continue;

    AddMetadata(F, impl);
  }
}

void AutoPodArgsPass::AddMetadata(Function &F, clspv::PodArgImpl impl) {
  auto md = MDTuple::get(
      F.getContext(),
      ConstantAsMetadata::get(ConstantInt::get(
          IntegerType::get(F.getContext(), 32), static_cast<uint32_t>(impl))));
  F.setMetadata(clspv::PodArgsImplMetadataName(), md);
}

bool AutoPodArgsPass::ContainsArrayType(Type *type) const {
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

bool AutoPodArgsPass::ContainsSizedType(Type *type, uint32_t width) const {
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
