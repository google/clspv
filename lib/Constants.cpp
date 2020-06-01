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

#include "Constants.h"
#include "Builtins.h"

namespace clspv {

const std::string &LocalSpecIdMetadataName() {
  static std::string func_name =
      Builtins::GetMangledFunctionName("clspv.local_spec_ids");
  return func_name;
}

const std::string &WorkgroupAccessorFunction() {
  static std::string func_name =
      Builtins::GetMangledFunctionName("clspv.local");
  return func_name;
}

const std::string &ResourceAccessorFunction() {
  static std::string func_name =
      Builtins::GetMangledFunctionName("clspv.resource");
  return func_name;
}

const std::string &RemappedTypeOffsetMetadataName() {
  static std::string func_name =
      Builtins::GetMangledFunctionName("clspv.remapped_offsets");
  return func_name;
}

const std::string &RemappedTypeSizesMetadataName() {
  static std::string func_name =
      Builtins::GetMangledFunctionName("clspv.remapped_type_sizes");
  return func_name;
}

const std::string &LiteralSamplerFunction() {
  static std::string func_name =
      Builtins::GetMangledFunctionName("clspv.sampler_var_literal");
  return func_name;
}

const std::string &CompositeConstructFunction() {
  static std::string func_name =
      Builtins::GetMangledFunctionName("clspv.composite_construct");
  return func_name;
}

const std::string &PackFunction() {
  static std::string func_name =
      Builtins::GetMangledFunctionName("spirv.pack.v2f16");
  return func_name;
}

const std::string &UnpackFunction() {
  static std::string func_name =
      Builtins::GetMangledFunctionName("spirv.unpack.v2f16");
  return func_name;
}

const std::string &CopyMemoryFunction() {
  static std::string func_name =
      Builtins::GetMangledFunctionName("spirv.copy_memory");
  return func_name;
}

const std::string &SPIRVOpIntrinsicFunction() {
  static std::string func_name = Builtins::GetMangledFunctionName("spirv.op");
  return func_name;
}

} // namespace clspv
