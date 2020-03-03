// Copyright 2018 The Clspv Authors. All rights reserved.
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

#ifndef CLSPV_LIB_CONSTANTS_H_
#define CLSPV_LIB_CONSTANTS_H_

#include <string>

namespace clspv {

// Name for module level metadata storing workgroup argument spec ids.
inline std::string LocalSpecIdMetadataName() { return "clspv.local_spec_ids"; }

// Base name for workgroup variable accessor function.
inline std::string WorkgroupAccessorFunction() { return "clspv.local.var."; }

// Base name for resource variable accessor function.
inline std::string ResourceAccessorFunction() { return "clspv.resource.var."; }

// Name for module level metadata storing UBO remapped type offsets.
inline std::string RemappedTypeOffsetMetadataName() {
  return "clspv.remapped.offsets";
}

// Name for module level metadata storing UBO remapped type sizes.
inline std::string RemappedTypeSizesMetadataName() {
  return "clspv.remapped.type.sizes";
}

// Name of the function used to encode literal samplers
inline std::string LiteralSamplerFunction() {
  return "clspv.sampler.var.literal";
}

// Base name for SPIR-V intrinsic functions
inline std::string SPIRVOpIntrinsicFunction() { return "spirv.op."; }

// The first useable SpecId for pointer-to-local arguments.
// 0, 1 and 2 are reserved for workgroup size.
inline int FirstLocalSpecId() { return 3; }

// Name of the literal sampler initializer function.
inline std::string TranslateSamplerInitializerFunction() {
  return "__translate_sampler_initializer";
}

// Name of the global variable storing all push constants
inline std::string PushConstantsVariableName() { return "__push_constants"; }

// Name for module level metadata storing push constant indices.
inline std::string PushConstantsMetadataName() { return "push_constants"; }

} // namespace clspv

#endif
