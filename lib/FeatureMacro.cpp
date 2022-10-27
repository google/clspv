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

#include "llvm/Support/raw_ostream.h"

#include "clspv/FeatureMacro.h"

#include <algorithm>

namespace clspv {

FeatureMacro FeatureMacroLookup(const std::string &name) {
  constexpr std::array<FeatureMacro, 4> NotSuppported{
      FeatureMacro::__opencl_c_pipes,
      FeatureMacro::__opencl_c_generic_address_space,
      FeatureMacro::__opencl_c_device_enqueue,
      FeatureMacro::__opencl_c_program_scope_global_variables};

  const auto macro_itr = std::find_if(
      FeatureMacroList.begin(), FeatureMacroList.end(),
      [name](const auto &macro) { return std::get<1>(macro) == name; });

  if (macro_itr != FeatureMacroList.end()) {
    const auto feature = std::get<0>(*macro_itr);
    const auto supported = std::find(NotSuppported.begin(), NotSuppported.end(),
                                     feature) == NotSuppported.end();

    if (supported)
      return feature;

    llvm::errs() << name << " is not a supported feature macro.\n";
  }

  return FeatureMacro::error;
}

} // namespace clspv
