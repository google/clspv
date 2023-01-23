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

#ifndef CLSPV_INCLUDE_CLSPV_PUSH_CONSTANT_H_
#define CLSPV_INCLUDE_CLSPV_PUSH_CONSTANT_H_

namespace clspv {

enum class PushConstant : int {
  Dimensions,
  GlobalOffset,
  EnqueuedLocalSize,
  GlobalSize,
  RegionOffset,
  NumWorkgroups,
  RegionGroupOffset,
  KernelArgument,
  ImageMetadata,
  ModuleConstantsPointer,
};

enum class ImageMetadata : int {
  ChannelOrder,
  ChannelDataType,
};

// Returns the name of the push constant from its enum.
const char *GetPushConstantName(PushConstant pc);

} // namespace clspv

#endif // #ifndef CLSPV_INCLUDE_CLSPV_PUSH_CONSTANT_H_
