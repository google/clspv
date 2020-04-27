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
clspv::ArgKind GetArgKindForType(Type *type);

// Maps an LLVM type for a kernel argument to an argument
// kind suitable for a descriptor map.  The result is one of:
//   buffer     - storage buffer
//   buffer_ubo - uniform buffer
//   local      - array in Workgroup storage, number of elements given by
//                a specialization constant
//   pod        - plain-old-data
//   ro_image   - read-only image
//   wo_image   - write-only image
//   sampler    - sampler
inline const char *GetArgKindNameForType(llvm::Type *type) {
  return GetArgKindName(GetArgKindForType(type));
}

clspv::ArgKind GetArgKindForType(Type *type) {
  if (type->isPointerTy()) {
    if (clspv::IsSamplerType(type)) {
      return clspv::ArgKind::Sampler;
    }
    llvm::Type *image_type = nullptr;
    if (clspv::IsImageType(type, &image_type)) {
      StringRef name = dyn_cast<StructType>(image_type)->getName();
      // OpenCL 1.2 only has read-only or write-only images.
      return name.contains("_ro_t") ? clspv::ArgKind::ReadOnlyImage
                                    : clspv::ArgKind::WriteOnlyImage;
    }
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
  } else {
    if (clspv::Option::PodArgsInUniformBuffer())
      return clspv::ArgKind::PodUBO;
    else if (clspv::Option::PodArgsInPushConstants())
      return clspv::ArgKind::PodPushConstant;
    else
      return clspv::ArgKind::Pod;
  }
  errs() << "Unhandled case in clspv::GetArgKindNameForType: " << *type << "\n";
  llvm_unreachable("Unhandled case in clspv::GetArgKindNameForType");
  return clspv::ArgKind::Buffer;
}
} // namespace

namespace clspv {

PodArgImpl GetPodArgsImpl(Function &F) {
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
}

ArgKind GetArgKind(Argument &Arg) {
  if (!isa<PointerType>(Arg.getType()) &&
      Arg.getParent()->getCallingConv() == CallingConv::SPIR_KERNEL) {
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
  case ArgKind::ReadOnlyImage:
    return "ro_image";
  case ArgKind::WriteOnlyImage:
    return "wo_image";
  case ArgKind::Sampler:
    return "sampler";
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
    return ArgKind::ReadOnlyImage;
  } else if (name == "wo_image") {
    return ArgKind::WriteOnlyImage;
  } else if (name == "sampler") {
    return ArgKind::Sampler;
  }

  llvm_unreachable("Unhandled case in clspv::GetArgKindFromName");
  return ArgKind::Buffer;
}

bool IsLocalPtr(llvm::Type *type) {
  return type->isPointerTy() &&
         type->getPointerAddressSpace() == clspv::AddressSpace::Local;
}

ArgIdMapType AllocateArgSpecIds(Module &M) {
  ArgIdMapType result;

  int next_spec_id = 3; // Reserve space for workgroup size spec ids.
  for (Function &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL) {
      continue;
    }
    for (const auto &Arg : F.args()) {
      if (IsLocalPtr(Arg.getType())) {
        result[&Arg] = next_spec_id++;
      }
    }
  }

  return result;
}

} // namespace clspv
