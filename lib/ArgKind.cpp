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
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/AddressSpace.h"
#include "clspv/Option.h"

#include "Types.h"

using namespace llvm;

namespace clspv {

ArgKind GetArgKindForType(Type *type) {
  if (type->isPointerTy()) {
    if (IsSamplerType(type)) {
      return ArgKind::Sampler;
    }
    llvm::Type *image_type = nullptr;
    if (IsImageType(type, &image_type)) {
      StringRef name = dyn_cast<StructType>(image_type)->getName();
      // OpenCL 1.2 only has read-only or write-only images.
      return name.contains("_ro_t") ? ArgKind::ReadOnlyImage
                                    : ArgKind::WriteOnlyImage;
    }
    switch (type->getPointerAddressSpace()) {
    // Pointer to constant and pointer to global are both in
    // storage buffers.
    case clspv::AddressSpace::Global:
      return ArgKind::Buffer;
    case clspv::AddressSpace::Constant:
      return Option::ConstantArgsInUniformBuffer() ? ArgKind::BufferUBO
                                                   : ArgKind::Buffer;
    case clspv::AddressSpace::Local:
      return ArgKind::Local;
    default:
      break;
    }
  } else {
    return ArgKind::Pod;
  }
  errs() << "Unhandled case in clspv::GetArgKindNameForType: " << *type << "\n";
  llvm_unreachable("Unhandled case in clspv::GetArgKindNameForType");
  return ArgKind::Buffer;
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
