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

#include <map>

#include "Builtins.h"
#include "Constants.h"
#include "PushConstant.h"
#include "SetImageChannelMetadataPass.h"

using namespace llvm;

#define DEBUG_TYPE "setimagechannelmetadata"

namespace {

using ImageGetterMap =
    std::map<std::pair<unsigned, unsigned>, SmallVector<CallInst *, 1>>;
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

void concatWithFunctionMetadata(Function *F, MetadataVector &MDs) {
  auto fct_md = F->getMetadata(clspv::PushConstantsMetadataImageChannelName());
  if (fct_md != nullptr) {
    for (unsigned i = 0; i < fct_md->getNumOperands(); i++) {
      MDs.push_back(fct_md->getOperand(i));
    }
  }
}

unsigned setMetadata(Module &M, Function *F, ImageGetterMap &map) {
  auto i32 = IntegerType::get(M.getContext(), 32);

  unsigned int count = 0;
  for (auto elem : map) {
    auto pc = elem.first.first;
    auto ordinal = elem.first.second;
    auto calls = elem.second;

    unsigned offset = count++;

    MetadataVector MDs = {
        ConstantAsMetadata::get(ConstantInt::get(i32, ordinal)),
        ConstantAsMetadata::get(ConstantInt::get(i32, offset)),
        ConstantAsMetadata::get(ConstantInt::get(i32, pc))};
    concatWithFunctionMetadata(F, MDs);
    // Set metadata for the function to be able to generate the appropriate
    // reflection from it
    F->setMetadata(clspv::PushConstantsMetadataImageChannelName(),
                   MDNode::get(M.getContext(), MDs));

    auto call_md =
        MDNode::get(M.getContext(),
                    {ConstantAsMetadata::get(ConstantInt::get(i32, offset))});
    for (auto call : calls) {
      // Set metadata for the call to be able to generate the appropriate gep
      // with the correct offset from it
      call->setMetadata(clspv::ImageGetterPushConstantOffsetName(), call_md);
    }
  }
  return count;
}

void updatePushConstant(Module &M, unsigned max_elements) {
  // Create and return the structure that will contains the needed values
  std::vector<Type *> orderTypes(max_elements,
                                 IntegerType::get(M.getContext(), 32));
  StructType *Ty = StructType::get(M.getContext(), orderTypes);

  clspv::RedeclareGlobalPushConstants(M, Ty,
                                      (int)clspv::PushConstant::ImageMetadata);
}
} // namespace

PreservedAnalyses
clspv::SetImageChannelMetadataPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  unsigned max_elements = 0;

  // Go through function and instruction to look for image metadata getter
  // function
  for (Function &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL) {
      continue;
    }
    ImageGetterMap Map;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto call = dyn_cast<CallInst>(&I)) {
          auto Name = call->getCalledFunction()->getName();
          if (Name.contains("get_image_channel_order")) {
            unsigned ordinal = getImageOrdinal(call->getArgOperand(0));
            Map[std::make_pair((unsigned)clspv::ImageMetadata::ChannelOrder,
                               ordinal)]
                .push_back(call);
          } else if (Name.contains("get_image_channel_data_type")) {
            unsigned ordinal = getImageOrdinal(call->getArgOperand(0));
            Map[std::make_pair((unsigned)clspv::ImageMetadata::ChannelDataType,
                               ordinal)]
                .push_back(call);
          }
        }
      }
    }
    max_elements = std::max(max_elements, setMetadata(M, &F, Map));
  }

  if (max_elements > 0)
    updatePushConstant(M, max_elements);

  return PA;
}
