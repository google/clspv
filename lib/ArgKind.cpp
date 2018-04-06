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

#include "llvm/ADT/StringSwitch.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/AddressSpace.h"


using namespace llvm;

namespace clspv {

const char *GetArgKindForType(Type *type) {
  if (type->isPointerTy()) {
    auto pointeeTy = type->getPointerElementType();
    if (auto structTy = dyn_cast<StructType>(pointeeTy)) {
      if (structTy->hasName()) {
        StringRef name = structTy->getName();
        const char *result = StringSwitch<const char *>(name)
                                 .Case("opencl.image2d_ro_t", "ro_image")
                                 .Case("opencl.image3d_ro_t", "ro_image")
                                 .Case("opencl.image2d_wo_t", "wo_image")
                                 .Case("opencl.image3d_wo_t", "wo_image")
                                 .Case("opencl.sampler_t", "sampler")
                                 .Default(nullptr);
        if (result) {
          return result;
        }
      }
    }
    switch (type->getPointerAddressSpace()) {
    // Pointer to constant and pointer to global are both in
    // storage buffers.
    case clspv::AddressSpace::Global:
    case clspv::AddressSpace::Constant:
      return "buffer";
    case clspv::AddressSpace::Local:
      return "local";
    default:
      break;
    }
  } else {
    return "pod";
  }
  errs() << "Unhandled case in clspv::GetArgKindForType: " << *type << "\n";
  llvm_unreachable("Unhandled case in clspv::GetArgKindForType");
  return nullptr;
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
