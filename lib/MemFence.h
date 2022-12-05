// Copyright 2017 The Clspv Authors. All rights reserved.
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

#ifndef CLSPV_INCLUDE_CLSPV_MEM_FENCE_H_
#define CLSPV_INCLUDE_CLSPV_MEM_FENCE_H_

namespace clspv {
namespace MemFence {

enum MemFenceType {
  CLK_NO_MEM_FENCE = 0x00,
  CLK_LOCAL_MEM_FENCE = 0x01,
  CLK_GLOBAL_MEM_FENCE = 0x02,
  CLK_IMAGE_MEM_FENCE = 0x04
}; // enum MemFenceType

} // namespace MemFence
} // namespace clspv

#endif // CLSPV_INCLUDE_CLSPV_MEM_FENCE_H_
