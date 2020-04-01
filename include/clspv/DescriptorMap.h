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

#ifndef CLSPV_INCLUDE_CLSPV_DESCRIPTOR_MAP_H_
#define CLSPV_INCLUDE_CLSPV_DESCRIPTOR_MAP_H_

#include <iosfwd>
#include <string>

#include "clspv/ArgKind.h"
#include "clspv/PushConstant.h"

namespace clspv {
namespace version0 {

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

struct DescriptorMapEntry {
  // Type of the entry.
  enum Kind { Sampler, KernelArg, KernelDecl, Constant, PushConstant } kind;

  // Common data.
  uint32_t descriptor_set;
  uint32_t binding;

  struct SamplerData {
    uint32_t mask;
  } sampler_data;

  struct KernelArgData {
    std::string kernel_name;
    std::string arg_name;
    uint32_t arg_ordinal;
    ArgKind arg_kind;

    // Pointer-to-local data.
    uint32_t local_spec_id;
    uint32_t local_element_size;

    // POD data.
    uint32_t pod_offset;
    uint32_t pod_arg_size;
  } kernel_arg_data;

  struct KernelDeclData {
    std::string kernel_name;
  } kernel_decl_data;

  struct ConstantData {
    ArgKind constant_kind;
    std::string hex_bytes;
  } constant_data;

  struct PushConstantData {
    clspv::PushConstant pc;
    uint32_t offset;
    uint32_t size;
  } push_constant_data;

  DescriptorMapEntry(PushConstantData &&data)
      : kind(PushConstant), descriptor_set(-1), binding(-1),
        push_constant_data(std::move(data)) {}

  DescriptorMapEntry(ConstantData &&data, uint32_t ds, uint32_t b)
      : kind(Constant), descriptor_set(ds), binding(b),
        constant_data(std::move(data)) {}

  DescriptorMapEntry(KernelArgData &&data, uint32_t ds, uint32_t b)
      : kind(KernelArg), descriptor_set(ds), binding(b),
        kernel_arg_data(std::move(data)) {}

  DescriptorMapEntry(KernelDeclData &&data)
      : kind(KernelDecl), descriptor_set(-1), binding(-1),
        kernel_decl_data(std::move(data)) {}

  DescriptorMapEntry(SamplerData &&data, uint32_t ds, uint32_t b)
      : kind(Sampler), descriptor_set(ds), binding(b),
        sampler_data(std::move(data)) {}
};

std::ostream &operator<<(std::ostream &str,
                         const DescriptorMapEntry::Kind &kind);
std::ostream &operator<<(std::ostream &str, const DescriptorMapEntry &entry);

} // namespace version0
} // namespace clspv

#endif // CLSPV_INCLUDE_CLSPV_DESCRIPTOR_MAP_H_
