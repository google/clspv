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

#include <ostream>
#include <unordered_map>
#include <unordered_set>

#include "spirv/unified1/spirv.hpp"
#include "spirv-tools/libspirv.hpp"

#include "clspv/ArgKind.h"
#include "clspv/PushConstant.h"
#include "clspv/SpecConstant.h"
#include "clspv/spirv_reflection.hpp"

#include "ReflectionParser.h"

namespace {
class ReflectionParser {
public:
  ReflectionParser(std::ostream* ostr) :
    str(ostr)
  { }

  spv_result_t ParseInstruction(const spv_parsed_instruction_t *inst);
  clspv::ArgKind GetArgKindFromExtInst(uint32_t value);
  clspv::PushConstant GetPushConstantFromExtInst(uint32_t value);

private:
  std::ostream* str;
  uint32_t int_id = 0;
  std::unordered_set<uint32_t> import_ids;
  std::unordered_map<uint32_t, std::string> id_to_string;
  std::unordered_map<uint32_t, uint32_t> constants;
  std::unordered_map<uint32_t, std::string> kernel_names;
  std::unordered_map<uint32_t, std::string> arg_names;
};

spv_result_t ParseHeader(void *, spv_endianness_t, uint32_t, uint32_t, uint32_t,
                         uint32_t, uint32_t) {
  return SPV_SUCCESS;
}

spv_result_t
ParseInstruction(void *user_data,
                 const spv_parsed_instruction_t *inst) {
  ReflectionParser *parser = reinterpret_cast<ReflectionParser *>(user_data);
  return parser->ParseInstruction(inst);
}

clspv::ArgKind ReflectionParser::GetArgKindFromExtInst(uint32_t value) {
  clspv::reflection::ExtInst ext_inst =
      static_cast<clspv::reflection::ExtInst>(value);
  switch (ext_inst) {
    case clspv::reflection::ExtInstArgumentStorageBuffer:
    case clspv::reflection::ExtInstConstantDataStorageBuffer:
      return clspv::ArgKind::Buffer;
    case clspv::reflection::ExtInstArgumentUniform:
    case clspv::reflection::ExtInstConstantDataUniform:
      return clspv::ArgKind::BufferUBO;
    case clspv::reflection::ExtInstArgumentPodStorageBuffer:
      return clspv::ArgKind::Pod;
    case clspv::reflection::ExtInstArgumentPodUniform:
      return clspv::ArgKind::PodUBO;
    case clspv::reflection::ExtInstArgumentPodPushConstant:
      return clspv::ArgKind::PodPushConstant;
    case clspv::reflection::ExtInstArgumentSampledImage:
      return clspv::ArgKind::ReadOnlyImage;
    case clspv::reflection::ExtInstArgumentStorageImage:
      return clspv::ArgKind::WriteOnlyImage;
    case clspv::reflection::ExtInstArgumentSampler:
      return clspv::ArgKind::Sampler;
    case clspv::reflection::ExtInstArgumentWorkgroup:
      return clspv::ArgKind::Local;
    default:
      assert(false && "Unexpected extended instruction");
      return clspv::ArgKind::Buffer;
  }
}

clspv::PushConstant
ReflectionParser::GetPushConstantFromExtInst(uint32_t value) {
  clspv::reflection::ExtInst ext_inst =
      static_cast<clspv::reflection::ExtInst>(value);
  switch (ext_inst) {
  case clspv::reflection::ExtInstPushConstantGlobalOffset:
    return clspv::PushConstant::GlobalOffset;
  case clspv::reflection::ExtInstPushConstantEnqueuedLocalSize:
    return clspv::PushConstant::EnqueuedLocalSize;
  case clspv::reflection::ExtInstPushConstantGlobalSize:
    return clspv::PushConstant::GlobalSize;
  case clspv::reflection::ExtInstPushConstantRegionOffset:
    return clspv::PushConstant::RegionOffset;
  case clspv::reflection::ExtInstPushConstantNumWorkgroups:
    return clspv::PushConstant::NumWorkgroups;
  case clspv::reflection::ExtInstPushConstantRegionGroupOffset:
    return clspv::PushConstant::RegionGroupOffset;
  default:
    assert(false && "Unexpected push constant");
    return clspv::PushConstant::KernelArgument;
  }
}

spv_result_t
ReflectionParser::ParseInstruction(const spv_parsed_instruction_t *inst) {
  switch (inst->opcode) {
  case spv::OpTypeInt:
    if (inst->words[inst->operands[1].offset] == 32 &&
        inst->words[inst->operands[2].offset] == 0) {
      int_id = inst->result_id;
    }
    break;
  case spv::OpConstant:
    if (inst->words[inst->operands[0].offset] == int_id) {
      uint32_t value = inst->words[inst->operands[2].offset];
      constants[inst->result_id] = value;
    }
    break;
  case spv::OpString: {
    std::string value =
        reinterpret_cast<const char *>(inst->words + inst->operands[1].offset);
    id_to_string[inst->result_id] = value;
    break;
  }
  case spv::OpExtInst:
    if (inst->ext_inst_type == SPV_EXT_INST_TYPE_NONSEMANTIC_CLSPVREFLECTION) {
      // Reflection sepcific instruction.
      auto ext_inst = inst->words[inst->operands[3].offset];
      switch (ext_inst) {
      case clspv::reflection::ExtInstKernel: {
        // Record the name and emit a kernel_decl entry.
        const auto &name = id_to_string[inst->words[inst->operands[5].offset]];
        kernel_names[inst->result_id] = name;
        *str << "kernel_decl," << name << "\n";
        break;
      }
      case clspv::reflection::ExtInstArgumentInfo: {
        // Record the argument name.
        const auto &name = id_to_string[inst->words[inst->operands[4].offset]];
        arg_names[inst->result_id] = name;
        break;
      }
      case clspv::reflection::ExtInstArgumentStorageBuffer:
      case clspv::reflection::ExtInstArgumentUniform:
      case clspv::reflection::ExtInstArgumentSampledImage:
      case clspv::reflection::ExtInstArgumentStorageImage:
      case clspv::reflection::ExtInstArgumentSampler: {
        // Emit an argument entry. Descriptor set and binding, no size.
        auto kernel_id = inst->words[inst->operands[4].offset];
        auto ordinal_id = inst->words[inst->operands[5].offset];
        auto ds_id = inst->words[inst->operands[6].offset];
        auto binding_id = inst->words[inst->operands[7].offset];
        std::string arg_name;
        if (inst->num_operands == 9) {
          arg_name = arg_names[inst->words[inst->operands[8].offset]];
        }
        auto kind = GetArgKindFromExtInst(ext_inst);
        *str << "kernel," << kernel_names[kernel_id] << ",arg," << arg_name
             << ",argOrdinal," << constants[ordinal_id] << ",descriptorSet,"
             << constants[ds_id] << ",binding," << constants[binding_id]
             << ",offset,0,argKind," << clspv::GetArgKindName(kind) << "\n";
        break;
      }
      case clspv::reflection::ExtInstArgumentPodStorageBuffer:
      case clspv::reflection::ExtInstArgumentPodUniform: {
        // Emit an argument entry. Descriptor set, binding and bize.
        auto kernel_id = inst->words[inst->operands[4].offset];
        auto ordinal_id = inst->words[inst->operands[5].offset];
        auto ds_id = inst->words[inst->operands[6].offset];
        auto binding_id = inst->words[inst->operands[7].offset];
        auto offset_id = inst->words[inst->operands[8].offset];
        auto size_id = inst->words[inst->operands[9].offset];
        std::string arg_name;
        if (inst->num_operands == 11) {
          arg_name = arg_names[inst->words[inst->operands[10].offset]];
        }
        auto kind = GetArgKindFromExtInst(ext_inst);
        *str << "kernel," << kernel_names[kernel_id] << ",arg," << arg_name
             << ",argOrdinal," << constants[ordinal_id] << ",descriptorSet,"
             << constants[ds_id] << ",binding," << constants[binding_id]
             << ",offset," << constants[offset_id] << ",argKind,"
             << clspv::GetArgKindName(kind) << ",argSize," << constants[size_id]
             << "\n";
        break;
      }
      case clspv::reflection::ExtInstArgumentPodPushConstant: {
        // Emit an argument entry. No descriptor set or binding, but has
        // size.
        auto kernel_id = inst->words[inst->operands[4].offset];
        auto ordinal_id = inst->words[inst->operands[5].offset];
        auto offset_id = inst->words[inst->operands[6].offset];
        auto size_id = inst->words[inst->operands[7].offset];
        std::string arg_name;
        if (inst->num_operands == 9) {
          arg_name = arg_names[inst->words[inst->operands[8].offset]];
        }
        auto kind = GetArgKindFromExtInst(ext_inst);
        *str << "kernel," << kernel_names[kernel_id] << ",arg," << arg_name
             << ",argOrdinal," << constants[ordinal_id] << ",offset,"
             << constants[offset_id] << ",argKind,"
             << clspv::GetArgKindName(kind) << ",argSize," << constants[size_id]
             << "\n";
        break;
      }
      case clspv::reflection::ExtInstArgumentWorkgroup: {
        // Emit an argument entry. No descriptor set or binding, but has
        // spec id and size.
        auto kernel_id = inst->words[inst->operands[4].offset];
        auto ordinal_id = inst->words[inst->operands[5].offset];
        auto spec_id = inst->words[inst->operands[6].offset];
        auto size_id = inst->words[inst->operands[7].offset];
        std::string arg_name;
        if (inst->num_operands == 9) {
          arg_name = arg_names[inst->words[inst->operands[8].offset]];
        }
        auto kind = GetArgKindFromExtInst(ext_inst);
        *str << "kernel," << kernel_names[kernel_id] << ",arg," << arg_name
             << ",argOrdinal," << constants[ordinal_id] << ",argKind,"
             << clspv::GetArgKindName(kind) << ",arrayElemSize,"
             << constants[size_id] << ",arrayNumElemSpecId,"
             << constants[spec_id] << "\n";
        break;
      }
      case clspv::reflection::ExtInstConstantDataStorageBuffer:
      case clspv::reflection::ExtInstConstantDataUniform: {
        // Emit constant data entry.
        auto ds_id = inst->words[inst->operands[4].offset];
        auto binding_id = inst->words[inst->operands[5].offset];
        auto data_id = inst->words[inst->operands[6].offset];
        auto kind = GetArgKindFromExtInst(ext_inst);
        *str << "constant,descriptorSet," << constants[ds_id] << ",binding,"
             << constants[binding_id] << ",kind," << clspv::GetArgKindName(kind)
             << ",hexbytes," << id_to_string[data_id] << "\n";
        break;
      }
      case clspv::reflection::ExtInstSpecConstantWorkgroupSize: {
        auto x_id = inst->words[inst->operands[4].offset];
        auto y_id = inst->words[inst->operands[5].offset];
        auto z_id = inst->words[inst->operands[6].offset];
        *str << clspv::GetSpecConstantName(clspv::SpecConstant::kWorkgroupSizeX)
             << ",spec_id," << constants[x_id] << "\n";
        *str << clspv::GetSpecConstantName(clspv::SpecConstant::kWorkgroupSizeY)
             << ",spec_id," << constants[y_id] << "\n";
        *str << clspv::GetSpecConstantName(clspv::SpecConstant::kWorkgroupSizeZ)
             << ",spec_id," << constants[z_id] << "\n";
        break;
      }
      case clspv::reflection::ExtInstSpecConstantGlobalOffset: {
        auto x_id = inst->words[inst->operands[4].offset];
        auto y_id = inst->words[inst->operands[5].offset];
        auto z_id = inst->words[inst->operands[6].offset];
        *str << clspv::GetSpecConstantName(clspv::SpecConstant::kGlobalOffsetX)
             << ",spec_id," << constants[x_id] << "\n";
        *str << clspv::GetSpecConstantName(clspv::SpecConstant::kGlobalOffsetY)
             << ",spec_id," << constants[y_id] << "\n";
        *str << clspv::GetSpecConstantName(clspv::SpecConstant::kGlobalOffsetZ)
             << ",spec_id," << constants[z_id] << "\n";
        break;
      }
      case clspv::reflection::ExtInstSpecConstantWorkDim: {
        auto dim_id = inst->words[inst->operands[4].offset];
        *str << clspv::GetSpecConstantName(clspv::SpecConstant::kWorkDim)
             << ",spec_id," << constants[dim_id] << "\n";
        break;
      }
      case clspv::reflection::ExtInstPushConstantGlobalOffset:
      case clspv::reflection::ExtInstPushConstantEnqueuedLocalSize:
      case clspv::reflection::ExtInstPushConstantGlobalSize:
      case clspv::reflection::ExtInstPushConstantRegionOffset:
      case clspv::reflection::ExtInstPushConstantNumWorkgroups:
      case clspv::reflection::ExtInstPushConstantRegionGroupOffset: {
        auto offset_id = inst->words[inst->operands[4].offset];
        auto size_id = inst->words[inst->operands[5].offset];
        auto kind = GetPushConstantFromExtInst(ext_inst);
        *str << "pushconstant,name," << clspv::GetPushConstantName(kind)
             << ",offset," << constants[offset_id] << ",size,"
             << constants[size_id] << "\n";
        break;
      }
      default:
        break;
      }
      break;
    }
  default:
    break;
  }

  return SPV_SUCCESS;
}
} // namespace

namespace clspv {

bool ParseReflection(const std::vector<uint32_t>& binary, spv_target_env env, std::ostream* str) {
  ReflectionParser parser(str);
  auto MessageConsumer = [](spv_message_level_t, const char *,
                            const spv_position_t, const char *) {};
  spvtools::Context context(env);
  context.SetMessageConsumer(MessageConsumer);

  spv_result_t result =
      spvBinaryParse(context.CContext(), &parser, binary.data(), binary.size(),
                     ParseHeader, ParseInstruction, nullptr);

  return result == SPV_SUCCESS;
}

}
