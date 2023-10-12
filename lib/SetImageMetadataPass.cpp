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
#include <set>

#include "Builtins.h"
#include "Constants.h"
#include "PushConstant.h"
#include "SamplerUtils.h"
#include "SetImageMetadataPass.h"
#include "Types.h"
#include "clspv/Option.h"
#include "clspv/Sampler.h"

using namespace llvm;

#define DEBUG_TYPE "setimagemetadata"

namespace {

using ImageMdMap = std::map<std::pair<unsigned, unsigned>, std::set<Value *>>;
using MetadataVector = SmallVector<Metadata *, 3>;

unsigned getOrdinal(Value *Val) {
  auto *call = dyn_cast<CallInst>(Val);
  assert(call != nullptr);
  assert(clspv::Builtins::Lookup(call->getCalledFunction()).getType() ==
         clspv::Builtins::kClspvResource);
  return dyn_cast<ConstantInt>(
             call->getOperand(clspv::ClspvOperand::kResourceArgIndex))
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

void setImageSamplerMetadata(Module &M, Function *F, unsigned ordinal,
                             unsigned offset, unsigned pc,
                             std::set<Value *> &samplers) {
  DenseMap<Value *, Type *> cache;
  auto i32 = IntegerType::get(M.getContext(), 32);
  MetadataVector MDs = {ConstantAsMetadata::get(ConstantInt::get(i32, ordinal)),
                        ConstantAsMetadata::get(ConstantInt::get(i32, offset))};
  concatWithFunctionMetadata(F, MDs);
  // Set metadata for the function to be able to generate the appropriate
  // reflection from it
  F->setMetadata(clspv::PushConstantMetadataSamplerMaskName(),
                 MDNode::get(M.getContext(), MDs));

  auto call_md = MDNode::get(
      M.getContext(), {ConstantAsMetadata::get(ConstantInt::get(i32, offset))});
  for (auto sampler : samplers) {
    for (auto *U : sampler->users()) {
      assert(isa<CallInst>(U));
      auto call = cast<CallInst>(U);
      IRBuilder<> B(call);
      Value *Coord = call->getOperand(2);
      Value *Img = call->getOperand(0);
      Type *ImgTy = clspv::InferType(Img, M.getContext(), &cache);
      Value *ImgDimFP = clspv::GetImageDimFP(M, B, Img, ImgTy);
      Value *NormCoordNearest =
          clspv::NormalizedCoordinate(M, B, Coord, ImgDimFP, true);
      Value *NormCoordLinear =
          clspv::NormalizedCoordinate(M, B, Coord, ImgDimFP, false);

      auto getSamplerNormFct =
          M.getOrInsertFunction("clspv.get_normalized_sampler_mask",
                                FunctionType::get(B.getInt32Ty(), {}, false));
      auto SamplerNorm = B.CreateCall(getSamplerNormFct, {});
      SamplerNorm->setMetadata(clspv::SamplerMaskPushConstantOffsetName(),
                               call_md);

      auto FilterMask =
          B.CreateAnd(SamplerNorm, B.getInt32(clspv::kSamplerFilterMask));
      auto FilterCond =
          B.CreateICmpEQ(FilterMask, B.getInt32(clspv::CLK_FILTER_NEAREST));
      if (clspv::Option::SpvVersion() <=
          clspv::Option::SPIRVVersion::SPIRV_1_3) {
        FilterCond = B.CreateVectorSplat(4, FilterCond);
      }

      auto NormCoord =
          B.CreateSelect(FilterCond, NormCoordNearest, NormCoordLinear);

      auto NormMask = B.CreateAnd(
          SamplerNorm, B.getInt32(clspv::kSamplerNormalizedCoordsMask));
      auto NormCond = B.CreateICmpEQ(
          NormMask, B.getInt32(clspv::CLK_NORMALIZED_COORDS_TRUE));
      if (clspv::Option::SpvVersion() <=
          clspv::Option::SPIRVVersion::SPIRV_1_3) {
        NormCond = B.CreateVectorSplat(4, NormCond);
      }

      auto Select = B.CreateSelect(NormCond, Coord, NormCoord);

      call->setOperand(2, Select);
    }
  }
}

void setImageChannelMetadata(Module &M, Function *F, unsigned ordinal,
                             unsigned offset, unsigned pc,
                             std::set<Value *> &calls) {
  auto i32 = IntegerType::get(M.getContext(), 32);
  MetadataVector MDs = {ConstantAsMetadata::get(ConstantInt::get(i32, ordinal)),
                        ConstantAsMetadata::get(ConstantInt::get(i32, offset)),
                        ConstantAsMetadata::get(ConstantInt::get(i32, pc))};
  concatWithFunctionMetadata(F, MDs);
  // Set metadata for the function to be able to generate the appropriate
  // reflection from it
  F->setMetadata(clspv::PushConstantsMetadataImageChannelName(),
                 MDNode::get(M.getContext(), MDs));

  auto call_md = MDNode::get(
      M.getContext(), {ConstantAsMetadata::get(ConstantInt::get(i32, offset))});
  for (auto call : calls) {
    assert(isa<CallInst>(call));
    // Set metadata for the call to be able to generate the appropriate gep
    // with the correct offset from it
    cast<CallInst>(call)->setMetadata(
        clspv::ImageGetterPushConstantOffsetName(), call_md);
  }
}

unsigned setMetadata(Module &M, Function *F, ImageMdMap &map) {

  unsigned int count = 0;
  for (const auto &elem : map) {
    auto pc = elem.first.first;
    auto ordinal = elem.first.second;
    auto calls = elem.second;

    unsigned offset = count++;
    if (pc == (unsigned)clspv::ImageMetadata::NormalizedSamplerMask) {
      setImageSamplerMetadata(M, F, ordinal, offset, pc, calls);
    } else {
      setImageChannelMetadata(M, F, ordinal, offset, pc, calls);
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

PreservedAnalyses clspv::SetImageMetadataPass::run(Module &M,
                                                   ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  unsigned max_elements = 0;

  // Go through function and instruction to look for image metadata getter
  // function
  for (Function &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL) {
      continue;
    }
    ImageMdMap Map;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto call = dyn_cast<CallInst>(&I)) {
          auto Name = call->getCalledFunction()->getName();
          if (Name.contains("get_image_channel_order")) {
            unsigned ordinal = getOrdinal(call->getArgOperand(0));
            Map[std::make_pair((unsigned)clspv::ImageMetadata::ChannelOrder,
                               ordinal)]
                .insert(call);
          } else if (Name.contains("get_image_channel_data_type")) {
            unsigned ordinal = getOrdinal(call->getArgOperand(0));
            Map[std::make_pair((unsigned)clspv::ImageMetadata::ChannelDataType,
                               ordinal)]
                .insert(call);
          } else if (isReadImage3DWithNonLiteralSampler(call)) {
            auto sampler = call->getArgOperand(1);
            unsigned ordinal = getOrdinal(sampler);
            Map[std::make_pair(
                    (unsigned)clspv::ImageMetadata::NormalizedSamplerMask,
                    ordinal)]
                .insert(sampler);
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
