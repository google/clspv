// Copyright 2022 The Clspv Authors. All rights reserved.
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

#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include "Builtins.h"
#include "Constants.h"
#include "PushConstant.h"
#include "SetImageChannelMetadataPass.h"

using namespace llvm;

#define DEBUG_TYPE "setimagechannelmetadata"

namespace {

using ImageGetterMap =
    DenseMap<std::pair<Function *, Value *>, SmallVector<CallInst *, 1>>;
using OffsetMap = DenseMap<Function *, unsigned>;
using MetadataVector = SmallVector<Metadata *, 3>;

unsigned getImageOrdinal(Value *Image) {
  auto *img_call = dyn_cast<CallInst>(Image);
  assert(img_call != nullptr);
  assert(clspv::Builtins::Lookup(img_call->getCalledFunction()).getType() ==
         clspv::Builtins::kClspvResource);
  return dyn_cast<ConstantInt>(
             img_call->getOperand(clspv::ClspvOperand::kResourceArgIndex))
      ->getZExtValue();
}

unsigned getFunctionNextOffset(OffsetMap &off_map, Function *F) {
  if (off_map.find(F) == off_map.end()) {
    off_map[F] = 0;
  }
  return off_map[F]++;
}

void concatWithFunctionMetadatas(Function *F, MetadataVector &MDs) {
  auto fct_md = F->getMetadata(clspv::PushConstantsMetadataImageChannelName());
  if (fct_md != nullptr) {
    for (unsigned i = 0; i < fct_md->getNumOperands(); i++) {
      MDs.push_back(fct_md->getOperand(i));
    }
  }
}

void setMetadata(Module &M, ImageGetterMap &map, OffsetMap &off_map, int pc) {
  auto i32 = IntegerType::get(M.getContext(), 32);

  for (auto order : map) {
    auto F = order.first.first;
    auto image = order.first.second;

    unsigned offset = getFunctionNextOffset(off_map, F);
    unsigned ordinal = getImageOrdinal(image);

    MetadataVector MDs = {
        ConstantAsMetadata::get(ConstantInt::get(i32, ordinal)),
        ConstantAsMetadata::get(ConstantInt::get(i32, offset)),
        ConstantAsMetadata::get(ConstantInt::get(i32, pc))};
    concatWithFunctionMetadata(F, MDs);
    // Set metadata for the function to be able to generate the appropriate
    // reflexion from it
    F->setMetadata(clspv::PushConstantsMetadataImageChannelName(),
                   MDNode::get(M.getContext(), MDs));

    auto call_md =
        MDNode::get(M.getContext(),
                    {ConstantAsMetadata::get(ConstantInt::get(i32, offset))});
    for (auto call : order.second) {
      // Set metadata for the call to be able to generate the appropriate gep
      // with the correct offset from it
      call->setMetadata(clspv::ImageGetterPushConstantOffsetName(), call_md);
    }
  }
}

unsigned getMaxElementIn(OffsetMap &map) {
  unsigned max = 0;
  for (auto element : map) {
    unsigned local_max = element.second;
    max = std::max(max, local_max);
  }
  return max;
}

void updatePushConstant(Module &M, OffsetMap &off_map) {
  unsigned max_elements = getMaxElementIn(off_map);
  if (max_elements == 0)
    return;

  // Create and return the structure that will contains the needed values
  std::vector<Type *> orderTypes(max_elements,
                                 IntegerType::get(M.getContext(), 32));
  StructType *Ty = StructType::get(M.getContext(), orderTypes);

  // All of them are not ChannelOrder, but it does not matter, as it will just
  // be used to be skipped in spirvproducer.
  clspv::RedeclareGlobalPushConstants(M, Ty,
                                      (int)clspv::PushConstant::ChannelOrder);
}
} // namespace

PreservedAnalyses
clspv::SetImageChannelMetadataPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  ImageGetterMap MapOrder, MapDataType;
  OffsetMap off_map;

  // Go through function and instruction to look for image metadata getter
  // function
  for (Function &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL) {
      continue;
    }
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto call = dyn_cast<CallInst>(&I)) {
          auto Name = call->getCalledFunction()->getName();
          if (Name.contains("get_image_channel_order")) {
            Value *Image = call->getArgOperand(0);
            MapOrder[std::make_pair(&F, Image)].push_back(call);
          } else if (Name.contains("get_image_channel_data_type")) {
            Value *Image = call->getArgOperand(0);
            MapDataType[std::make_pair(&F, Image)].push_back(call);
          }
        }
      }
    }
  }

  setMetadata(M, MapOrder, off_map, (int)clspv::PushConstant::ChannelOrder);
  setMetadata(M, MapDataType, off_map,
               (int)clspv::PushConstant::ChannelDataType);

  updatePushConstant(M, off_map);

  return PA;
}
