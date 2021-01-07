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

#include "llvm/IR/Constants.h"

#include "Constants.h"
#include "SpecConstant.h"

using namespace llvm;

namespace {

void InitSpecConstantMetadata(Module *module) {
  auto next_spec_id_md =
      module->getOrInsertNamedMetadata(clspv::NextSpecConstantMetadataName());
  next_spec_id_md->clearOperands();

  // Start at 3 to accommodate workgroup size ids.
  const uint32_t first_spec_id = 3;
  auto id_const = ValueAsMetadata::getConstant(ConstantInt::get(
      IntegerType::get(module->getContext(), 32), first_spec_id));
  auto id_md = MDTuple::getDistinct(module->getContext(), {id_const});
  next_spec_id_md->addOperand(id_md);

  auto spec_constant_list_md =
      module->getOrInsertNamedMetadata(clspv::SpecConstantMetadataName());
  spec_constant_list_md->clearOperands();
}

} // namespace

namespace clspv {

const char *GetSpecConstantName(SpecConstant kind) {
  switch (kind) {
  case SpecConstant::kWorkgroupSizeX:
    return "workgroup_size_x";
  case SpecConstant::kWorkgroupSizeY:
    return "workgroup_size_y";
  case SpecConstant::kWorkgroupSizeZ:
    return "workgroup_size_z";
  case SpecConstant::kLocalMemorySize:
    return "local_memory_size";
  case SpecConstant::kWorkDim:
    return "work_dim";
  case SpecConstant::kGlobalOffsetX:
    return "global_offset_x";
  case SpecConstant::kGlobalOffsetY:
    return "global_offset_y";
  case SpecConstant::kGlobalOffsetZ:
    return "global_offset_z";
  }
  llvm::errs() << "Unhandled case in clspv::GetSpecConstantName: " << int(kind)
               << "\n";
  return "";
}

SpecConstant GetSpecConstantFromName(const std::string &name) {
  if (name == "workgroup_size_x")
    return SpecConstant::kWorkgroupSizeX;
  else if (name == "workgroup_size_y")
    return SpecConstant::kWorkgroupSizeY;
  else if (name == "workgroup_size_z")
    return SpecConstant::kWorkgroupSizeZ;
  else if (name == "local_memory_size")
    return SpecConstant::kLocalMemorySize;
  else if (name == "work_dim")
    return SpecConstant::kWorkDim;
  else if (name == "global_offset_x")
    return SpecConstant::kGlobalOffsetX;
  else if (name == "global_offset_y")
    return SpecConstant::kGlobalOffsetY;
  else if (name == "global_offset_z")
    return SpecConstant::kGlobalOffsetZ;

  llvm::errs() << "Unhandled csae in clspv::GetSpecConstantFromName: " << name
               << "\n";
  return SpecConstant::kWorkgroupSizeX;
}

void AddWorkgroupSpecConstants(Module *module) {
  auto spec_constant_list_md =
      module->getNamedMetadata(SpecConstantMetadataName());
  if (!spec_constant_list_md) {
    InitSpecConstantMetadata(module);
    spec_constant_list_md =
        module->getNamedMetadata(SpecConstantMetadataName());
  }

  // Workgroup size spec constants always occupy ids 0, 1 and 2.
  auto enum_const = ValueAsMetadata::getConstant(
      ConstantInt::get(IntegerType::get(module->getContext(), 32),
                       static_cast<uint64_t>(SpecConstant::kWorkgroupSizeX)));
  auto id_const = ValueAsMetadata::getConstant(
      ConstantInt::get(IntegerType::get(module->getContext(), 32), 0));
  auto wg_md = MDTuple::get(module->getContext(), {enum_const, id_const});
  spec_constant_list_md->addOperand(wg_md);

  enum_const = ValueAsMetadata::getConstant(
      ConstantInt::get(IntegerType::get(module->getContext(), 32),
                       static_cast<uint64_t>(SpecConstant::kWorkgroupSizeY)));
  id_const = ValueAsMetadata::getConstant(
      ConstantInt::get(IntegerType::get(module->getContext(), 32), 1));
  wg_md = MDTuple::get(module->getContext(), {enum_const, id_const});
  spec_constant_list_md->addOperand(wg_md);

  enum_const = ValueAsMetadata::getConstant(
      ConstantInt::get(IntegerType::get(module->getContext(), 32),
                       static_cast<uint64_t>(SpecConstant::kWorkgroupSizeZ)));
  id_const = ValueAsMetadata::getConstant(
      ConstantInt::get(IntegerType::get(module->getContext(), 32), 2));
  wg_md = MDTuple::get(module->getContext(), {enum_const, id_const});
  spec_constant_list_md->addOperand(wg_md);
}

uint32_t AllocateSpecConstant(Module *module, SpecConstant kind) {
  auto spec_constant_id_md =
      module->getNamedMetadata(NextSpecConstantMetadataName());
  if (!spec_constant_id_md) {
    InitSpecConstantMetadata(module);
    spec_constant_id_md =
        module->getNamedMetadata(NextSpecConstantMetadataName());
  }

  auto value_md = spec_constant_id_md->getOperand(0);
  auto value = cast<ConstantInt>(
      dyn_cast<ValueAsMetadata>(value_md->getOperand(0))->getValue());
  uint32_t next_id = static_cast<uint32_t>(value->getZExtValue());
  // Update the next available id.
  value_md->replaceOperandWith(
      0, ValueAsMetadata::getConstant(ConstantInt::get(
             IntegerType::get(module->getContext(), 32), next_id + 1)));

  // Add the allocation to the metadata list.
  auto spec_constant_list_md =
      module->getNamedMetadata(SpecConstantMetadataName());
  auto enum_const = ValueAsMetadata::getConstant(ConstantInt::get(
      IntegerType::get(module->getContext(), 32), static_cast<uint64_t>(kind)));
  auto id_const = ValueAsMetadata::getConstant(
      ConstantInt::get(IntegerType::get(module->getContext(), 32), next_id));
  auto wg_md = MDTuple::get(module->getContext(), {enum_const, id_const});
  spec_constant_list_md->addOperand(wg_md);

  return next_id;
}

std::vector<std::pair<SpecConstant, uint32_t>>
GetSpecConstants(Module *module) {
  std::vector<std::pair<SpecConstant, uint32_t>> spec_constants;
  auto spec_constant_md =
      module->getNamedMetadata(clspv::SpecConstantMetadataName());
  if (!spec_constant_md)
    return spec_constants;

  for (auto pair : spec_constant_md->operands()) {
    // Metadata is formatted as pairs of <SpecConstant, id>.
    auto kind = static_cast<SpecConstant>(
        cast<ConstantInt>(
            cast<ValueAsMetadata>(pair->getOperand(0))->getValue())
            ->getZExtValue());

    uint32_t spec_id = static_cast<uint32_t>(
        cast<ConstantInt>(
            cast<ValueAsMetadata>(pair->getOperand(1))->getValue())
            ->getZExtValue());
    spec_constants.emplace_back(kind, spec_id);
  }

  return spec_constants;
}

} // namespace clspv
