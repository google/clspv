// Copyright 2023 The Clspv Authors. All rights reserved.
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

#include "SamplerUtils.h"
#include "Types.h"
#include "Constants.h"

using namespace llvm;

namespace clspv {

Value *GetImageDimFP(Module &M, IRBuilder<> &B, Value *Img, Type *ImgTy) {
  auto float4Ty = FixedVectorType::get(B.getFloatTy(), 4);
  auto getImageSizesFct = M.getOrInsertFunction(
      "_Z13get_image_dim11ocl_image3d",
      FunctionType::get(FixedVectorType::get(B.getInt32Ty(), 4), {ImgTy},
                        false));
  Value *ImgSizes = B.CreateCall(getImageSizesFct, {Img});
  return B.CreateSIToFP(ImgSizes, float4Ty);
}

Value *NormalizedCoordinate(Module &M, IRBuilder<> &B, Value *Coord,
                            Value *ImgDimFP, bool FilteringNearest) {
  if (FilteringNearest) {
    auto float4Ty = FixedVectorType::get(B.getFloatTy(), 4);
    auto getFloorFct = M.getOrInsertFunction(
        "floor", FunctionType::get(float4Ty, {float4Ty}, false));
    Coord = B.CreateCall(getFloorFct, {Coord});
    Coord = B.CreateFAdd(Coord, ConstantFP::get(float4Ty, 0.5));
  }

  return B.CreateFDiv(Coord, ImgDimFP);
}

bool isReadImage3DWithNonLiteralSampler(CallInst *call) {
  DenseMap<Value *, Type *> cache;
  auto Name = call->getCalledFunction()->getName();
  if (Name.contains("read_image") && Name.contains("ocl_sampler")) {
    Type *ImgTy =
        clspv::InferType(call->getOperand(0), call->getContext(), &cache);
    auto sampler_call = dyn_cast<CallInst>(call->getOperand(1));
    bool literal_sampler =
        sampler_call && (sampler_call->getCalledFunction()->getName().contains(
                             TranslateSamplerInitializerFunction()) ||
                         sampler_call->getCalledFunction()->getName().contains(
                             LiteralSamplerFunction()));
    if (clspv::ImageDimensionality(ImgTy) == spv::Dim3D && !literal_sampler) {
      return true;
    }
  }
  return false;
}

} // namespace clspv
