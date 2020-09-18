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

#ifndef CLSPV_INCLUDE_CLSPV_ARG_KIND_H_
#define CLSPV_INCLUDE_CLSPV_ARG_KIND_H_

#include <string>

namespace clspv {

enum class ArgKind : int {
  Buffer,
  BufferUBO,
  Local,
  Pod,
  PodUBO,
  PodPushConstant,
  SampledImage,
  StorageImage,
  Sampler,
};

// Converts an ArgKind to its string name.
const char *GetArgKindName(ArgKind);

// Converts a string into its ArgKind.
ArgKind GetArgKindFromName(const std::string &);

} // namespace clspv

#endif // CLSPV_INCLUDE_CLSPV_ARG_KIND_H_
