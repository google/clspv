// Copyright 2017 The Clspv Authors. All rights reserved.
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

#include <llvm/ADT/StringSwitch.h>
#include <llvm/ADT/StringRef.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/Type.h>

using namespace llvm;

namespace clspv {

const char *GetArgTypeForType(Type *type) {
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
                                 .Default("buffer");
        if (!result) {
          // Pointer to constant and pointer to global are both in
          // storage buffers.
          result = "buffer";
        }
        return result;
      }
    }
  } else {
    return "pod";
  }
  // This ought to be a dead code path.
  return "buffer";
}

} // namespace clspv
