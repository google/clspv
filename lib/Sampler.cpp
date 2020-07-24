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

#include <cassert>

#include "clspv/Sampler.h"

namespace clspv {

const char* GetSamplerCoordsName(uint32_t mask) {
  if (mask & kSamplerNormalizedCoordsMask)
    return "CLK_NORMALIZED_COORDS_TRUE";
  else
    return "CLK_NORMALIZED_COORDS_FALSE";
}

const char* GetSamplerAddressingModeName(uint32_t mask) {
  const auto addressing_mode = mask & kSamplerAddressMask;
  switch (addressing_mode) {
    case CLK_ADDRESS_NONE:
    default:
      return "CLK_ADDRESS_NONE";
    case CLK_ADDRESS_CLAMP_TO_EDGE:
      return "CLK_CLAMP_TO_EDGE";
    case CLK_ADDRESS_CLAMP:
      return "CLK_ADDRESS_CLAMP";
    case CLK_ADDRESS_REPEAT:
      return "CLK_ADDRESS_REPEAT";
    case CLK_ADDRESS_MIRRORED_REPEAT:
      return "CLK_ADDRESS_MIRRORED_REPEAT";
  }
}

const char* GetSamplerFilteringModeName(uint32_t mask) {
  const auto filtering_mode = mask & kSamplerFilterMask;
  if (filtering_mode == CLK_FILTER_NEAREST) {
    return "CLK_FILTER_NEAREST";
  } else if (filtering_mode == CLK_FILTER_LINEAR) {
    return "CLK_FILTER_LINEAR";
  } else {
    assert(false && "Unexpect filtering mode");
  }
  return "";
}


} // namespace clspv
