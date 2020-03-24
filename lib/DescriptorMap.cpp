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

#include <cassert>
#include <ostream>

#include "clspv/DescriptorMap.h"

#include "PushConstant.h"

namespace clspv {
namespace version0 {

std::ostream &operator<<(std::ostream &str,
                         const DescriptorMapEntry::Kind &kind) {
  switch (kind) {
  case DescriptorMapEntry::Kind::Sampler:
    str << "sampler";
    break;
  case DescriptorMapEntry::Kind::KernelArg:
    str << "kernel";
    break;
  case DescriptorMapEntry::Kind::KernelDecl:
    str << "kernel_decl";
    break;
  case DescriptorMapEntry::Kind::Constant:
    str << "constant";
    break;
  case DescriptorMapEntry::Kind::PushConstant:
    str << "pushconstant";
    break;
  default:
    assert(0 && "Unhandled descriptor map entry kind.");
    break;
  }
  return str;
}

std::ostream &operator<<(std::ostream &str, const DescriptorMapEntry &entry) {
  str << entry.kind << ",";
  switch (entry.kind) {
  case DescriptorMapEntry::Kind::Sampler: {
    const auto mask = entry.sampler_data.mask;
    str << mask << ",samplerExpr,\"";
    // See opencl-c.h for sampler expression definitions.
    // Coordinate normalization.
    if (mask & kSamplerNormalizedCoordsMask) {
      str << "CLK_NORMALIZED_COORDS_TRUE";
    } else {
      str << "CLK_NORMALIZED_COORDS_FALSE";
    }
    str << "|";
    // Addressing mode.
    const auto addressing_mode = mask & kSamplerAddressMask;
    switch (addressing_mode) {
    case CLK_ADDRESS_NONE:
      str << "CLK_ADDRESS_NONE";
      break;
    case CLK_ADDRESS_CLAMP_TO_EDGE:
      str << "CLK_ADDRESS_CLAMP_TO_EDGE";
      break;
    case CLK_ADDRESS_CLAMP:
      str << "CLK_ADDRESS_CLAMP";
      break;
    case CLK_ADDRESS_REPEAT:
      str << "CLK_ADDRESS_REPEAT";
      break;
    case CLK_ADDRESS_MIRRORED_REPEAT:
      str << "CLK_ADDRESS_MIRRORED_REPEAT";
      break;
    default:
      assert(0 && "Unexpected sampler adressing mode.");
      break;
    }
    str << "|";
    // Filtering mode.
    const auto filtering_mode = mask & kSamplerFilterMask;
    if (filtering_mode == CLK_FILTER_NEAREST) {
      str << "CLK_FILTER_NEAREST";
    } else if (filtering_mode == CLK_FILTER_LINEAR) {
      str << "CLK_FILTER_LINEAR";
    } else {
      assert(0 && "Unexpected sampler filtering mode.");
    }
    str << "\",descriptorSet," << entry.descriptor_set << ",binding,"
        << entry.binding;
    break;
  }
  case DescriptorMapEntry::Kind::KernelArg: {
    const auto &kernel_data = entry.kernel_arg_data;
    str << kernel_data.kernel_name << ",arg," << kernel_data.arg_name
        << ",argOrdinal," << kernel_data.arg_ordinal;
    if (kernel_data.arg_kind == ArgKind::Local) {
      str << ",argKind," << GetArgKindName(kernel_data.arg_kind)
          << ",arrayElemSize," << kernel_data.local_element_size
          << ",arrayNumElemSpecId," << kernel_data.local_spec_id;
    } else if (kernel_data.arg_kind == ArgKind::PodPushConstant) {
      str << ",offset," << kernel_data.pod_offset
          << ",argKind," << GetArgKindName(kernel_data.arg_kind)
          << ",argSize," << kernel_data.pod_arg_size;
    } else {
      str << ",descriptorSet," << entry.descriptor_set << ",binding,"
          << entry.binding << ",offset,";
      if (kernel_data.arg_kind == ArgKind::Pod ||
          kernel_data.arg_kind == ArgKind::PodUBO) {
        str << kernel_data.pod_offset;
      } else {
        str << "0";
      }
      str << ",argKind," << GetArgKindName(kernel_data.arg_kind);
      if (kernel_data.arg_kind == ArgKind::Pod ||
          kernel_data.arg_kind == ArgKind::PodUBO) {
        str << ",argSize," << kernel_data.pod_arg_size;
      }
    }
    break;
  }
  case DescriptorMapEntry::Kind::KernelDecl: {
    const auto &kernel_data = entry.kernel_decl_data;
    str << kernel_data.kernel_name;
    break;
  }
  case DescriptorMapEntry::Kind::Constant: {
    const auto &constant_data = entry.constant_data;
    str << "descriptorSet," << entry.descriptor_set << ",binding,"
        << entry.binding << ",kind,"
        << GetArgKindName(constant_data.constant_kind) << ",hexbytes,"
        << constant_data.hex_bytes;
    break;
  }
  case DescriptorMapEntry::Kind::PushConstant: {
    const auto &data = entry.push_constant_data;
    str << "name," << GetPushConstantName(data.pc) << ",offset," << data.offset
        << ",size," << data.size;
    break;
  }
  default:
    assert(0 && "Unhandled descriptor map entry kind.");
    break;
  }
  return str;
}

} // namespace version0
} // namespace clspv
