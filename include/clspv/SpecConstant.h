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

#ifndef CLSPV_INCLUDE_CLSPV_SPEC_CONSTANT_H_
#define CLSPV_INCLUDE_CLSPV_SPEC_CONSTANT_H_

#include <string>

namespace clspv {

enum class SpecConstant : int {
  // Workgroup size per dimension.
  kWorkgroupSizeX,
  kWorkgroupSizeY,
  kWorkgroupSizeZ,
  // Local memory array size.
  kLocalMemorySize,
  // Work dimensions.
  kWorkDim,
  // Global offset per dimension.
  kGlobalOffsetX,
  kGlobalOffsetY,
  kGlobalOffsetZ,
};

// Converts an SpecConstant to its string name.
const char *GetSpecConstantName(SpecConstant);

// Converts a string into its ArgKind.
SpecConstant GetSpecConstantFromName(const std::string &);

} // namespace clspv

#endif // CLSPV_INCLUDE_CLSPV_SPEC_CONSTANT_H_
