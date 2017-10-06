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

#ifndef CLSPV_LIB_ARGKIND_H_
#define CLSPV_LIB_ARGKIND_H_

#include <llvm/IR/Type.h>

namespace clspv {

// Maps an LLVM type for a kernel argument to an argument
// kind suitable for a descriptor map.  The result is one of:
//   buffer
//   pod
//   ro_image
//   wo_image
//   sampler
const char *GetArgKindForType(llvm::Type *type);

} // namespace clspv

#endif
