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

#ifndef CLSPV_INCLUDE_CLSPV_SAMPLER_H_
#define CLSPV_INCLUDE_CLSPV_SAMPLER_H_

#include <cstdint>

namespace clspv {

enum SamplerNormalizedCoords {
  CLK_NORMALIZED_COORDS_FALSE = 0x00,
  CLK_NORMALIZED_COORDS_TRUE = 0x01,
  CLK_NORMALIZED_COORDS_NOT_SET
};
const unsigned kSamplerNormalizedCoordsMask = 0x01;

enum SamplerAddressingMode {
  CLK_ADDRESS_NONE = 0x00,
  CLK_ADDRESS_CLAMP_TO_EDGE = 0x02,
  CLK_ADDRESS_CLAMP = 0x04,
  CLK_ADDRESS_MIRRORED_REPEAT = 0x08,
  CLK_ADDRESS_REPEAT = 0x06,
  CLK_ADDRESS_NOT_SET
};
const unsigned kSamplerAddressMask = 0x0e;

enum SamplerFilterMode {
  CLK_FILTER_NEAREST = 0x10,
  CLK_FILTER_LINEAR = 0x20,
  CLK_FILTER_NOT_SET
};
const unsigned kSamplerFilterMask = 0x30;

// Returns the name of the coordinate normalization in |mask|.
const char *GetSamplerCoordsName(uint32_t mask);

// Returns the name of the addressing mode in |mask|.
const char *GetSamplerAddressingModeName(uint32_t mask);

// Returns the name of the filter mode in |mask|.
const char *GetSamplerFilteringModeName(uint32_t mask);

} // namespace clspv

#endif // CLSPV_INCLUDE_CLSPV_SAMPLER_H_
