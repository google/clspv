// Copyright 2017-2018 The Clspv Authors. All rights reserved.
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

#include "ArgKind.h"

#include <cstring>

#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/IR/CallingConv.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/AddressSpace.h"
#include "clspv/Option.h"

#include "Constants.h"
#include "Types.h"

using namespace llvm;

namespace {

// Maps an LLVM type for a kernel argument to an argument kind.
clspv::ArgKind GetArgKindForType(Type *type) {
  if (isa<PointerType>(type)) {
    switch (type->getPointerAddressSpace()) {
    // Pointer to constant and pointer to global are both in
    // storage buffers.
    case clspv::AddressSpace::Global:
      return clspv::ArgKind::Buffer;
    case clspv::AddressSpace::Constant:
      return clspv::Option::ConstantArgsInUniformBuffer()
                 ? clspv::ArgKind::BufferUBO
                 : clspv::ArgKind::Buffer;
    case clspv::AddressSpace::Local:
      return clspv::ArgKind::Local;
    default:
      break;
    }
  } else if (auto *ext_ty = dyn_cast<TargetExtType>(type)) {
    if (clspv::IsSamplerType(ext_ty))
      return clspv::ArgKind::Sampler;
    if (clspv::IsImageType(ext_ty)) {
      if (clspv::IsSampledImageType(ext_ty)) {
        return clspv::ImageDimensionality(ext_ty) == spv::DimBuffer
                   ? clspv::ArgKind::UniformTexelBuffer
                   : clspv::ArgKind::SampledImage;
      } else {
        return clspv::ImageDimensionality(ext_ty) == spv::DimBuffer
                   ? clspv::ArgKind::StorageTexelBuffer
                   : clspv::ArgKind::StorageImage;
      }
    }
    errs() << "Unhandled target ext type: " << *type << "\n";
    llvm_unreachable("Unhandled target ext type");
  } else {
    if (clspv::Option::PodArgsInUniformBuffer())
      return clspv::ArgKind::PodUBO;
    else if (clspv::Option::PodArgsInPushConstants())
      return clspv::ArgKind::PodPushConstant;
    else
      return clspv::ArgKind::Pod;
  }
  errs() << "Unhandled case in clspv::GetArgKindForType: " << *type << "\n";
  llvm_unreachable("Unhandled case in clspv::GetArgKindForType");
  return clspv::ArgKind::Buffer;
}
} // namespace

namespace clspv {

PodArgImpl GetPodArgsImpl(Function &F) {
  assert(F.hasMetadata(PodArgsImplMetadataName()));
  auto md = F.getMetadata(PodArgsImplMetadataName());
  auto impl = static_cast<PodArgImpl>(
      cast<ConstantInt>(
          cast<ConstantAsMetadata>(md->getOperand(0).get())->getValue())
          ->getZExtValue());
  return impl;
}

ArgKind GetArgKindForPodArgs(Function &F) {
  auto impl = GetPodArgsImpl(F);
  switch (impl) {
  case kUBO:
    return ArgKind::PodUBO;
  case kPushConstant:
  case kGlobalPushConstant:
    return ArgKind::PodPushConstant;
  case kSSBO:
    return ArgKind::Pod;
  }
  errs() << "Unhandled case in clspv::GetArgKindForPodArgs: " << impl << "\n";
  llvm_unreachable("Unhandled case in clspv::GetArgKindForPodArgs");
}

ArgKind GetArgKindForPointerPodArgs(Function &F) {
  auto impl = GetPodArgsImpl(F);
  switch (impl) {
  case kUBO:
    return ArgKind::PointerUBO;
  case kPushConstant:
  case kGlobalPushConstant:
    return ArgKind::PointerPushConstant;
  case kSSBO:
    llvm_unreachable("SSBO PODs not supported with physical pointer arguments!");
  }
  llvm_unreachable("Unhandled case in clspv::GetArgKindForPodArgs");
}

ArgKind GetArgKind(Argument &Arg) {
  if (isa<TargetExtType>(Arg.getType())) {
    return GetArgKindForType(Arg.getType());
  } else if (!isa<PointerType>(Arg.getType()) &&
      Arg.getParent()->getCallingConv() == CallingConv::SPIR_KERNEL) {

    for (auto *Use : Arg.users()) {
      if (auto *Instr = dyn_cast<Instruction>(Use)) {
        if (Instr->getMetadata(clspv::PointerPodArgMetadataName())) {
          return GetArgKindForPointerPodArgs(*Arg.getParent());
        }
      }
    }

    return GetArgKindForPodArgs(*Arg.getParent());
  }

  return GetArgKindForType(Arg.getType());
}

const char *GetArgKindName(ArgKind kind) {
  switch (kind) {
  case ArgKind::Buffer:
    return "buffer";
  case ArgKind::BufferUBO:
    return "buffer_ubo";
  case ArgKind::Local:
    return "local";
  case ArgKind::Pod:
    return "pod";
  case ArgKind::PodUBO:
    return "pod_ubo";
  case ArgKind::PodPushConstant:
    return "pod_pushconstant";
  case ArgKind::SampledImage:
    // For historical purposes this string still refers to read-only images.
    return "ro_image";
  case ArgKind::StorageImage:
    // For historical purposes this string still refers to write-only images.
    return "wo_image";
  case ArgKind::Sampler:
    return "sampler";
  case ArgKind::PointerPushConstant:
    return "pointer_pushconstant";
  case ArgKind::PointerUBO:
    return "pointer_ubo";
  case ArgKind::StorageTexelBuffer:
    return "storage_texel_buffer";
  case ArgKind::UniformTexelBuffer:
    return "uniform_texel_buffer";
  }
  errs() << "Unhandled case in clspv::GetArgKindForType: " << int(kind) << "\n";
  llvm_unreachable("Unhandled case in clspv::GetArgKindForType");
  return "";
}

ArgKind GetArgKindFromName(const std::string &name) {
  if (name == "buffer") {
    return ArgKind::Buffer;
  } else if (name == "buffer_ubo") {
    return ArgKind::BufferUBO;
  } else if (name == "local") {
    return ArgKind::Local;
  } else if (name == "pod") {
    return ArgKind::Pod;
  } else if (name == "pod_ubo") {
    return ArgKind::PodUBO;
  } else if (name == "pod_pushconstant") {
    return ArgKind::PodPushConstant;
  } else if (name == "ro_image") {
    return ArgKind::SampledImage;
  } else if (name == "wo_image") {
    return ArgKind::StorageImage;
  } else if (name == "sampler") {
    return ArgKind::Sampler;
  } else if (name == "pointer_pushconstant") {
    return ArgKind::PointerPushConstant;
  } else if (name == "pointer_ubo") {
    return ArgKind::PointerUBO;
  } else if (name == "storage_texel_buffer") {
    return ArgKind::StorageTexelBuffer;
  } else if (name == "uniform_texel_buffer") {
    return ArgKind::UniformTexelBuffer;
  }
  llvm_unreachable("Unhandled case in clspv::GetArgKindFromName");
  return ArgKind::Buffer;
}

bool IsLocalPtr(llvm::Type *type) {
  return type->isPointerTy() &&
         type->getPointerAddressSpace() == clspv::AddressSpace::Local;
}

} // namespace clspv
