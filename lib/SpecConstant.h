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

#ifndef CLSPV_LIB_SPEC_CONSTANT_H_
#define CLSPV_LIB_SPEC_CONSTANT_H_

#include <utility>
#include <vector>

#include "clspv/SpecConstant.h"
#include "llvm/IR/Module.h"

namespace clspv {

// Record the use of workgroup size spec constants. Always uses 0, 1 and 2 as
// the spec ids.
void AddWorkgroupSpecConstants(llvm::Module *module);

// Allocates a specialization id for |kind|.
uint32_t AllocateSpecConstant(llvm::Module *module, SpecConstant kind);

// Returns the allocated specializations ids.
std::vector<std::pair<SpecConstant, uint32_t>> GetSpecConstants(llvm::Module *module);

} // namespace clspv

#endif // CLSPV_LIB_SPEC_CONSTANT_H_
