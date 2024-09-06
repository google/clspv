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

#ifndef CLSPV_LIB_FEATUREMACRO_H
#define CLSPV_LIB_FEATUREMACRO_H

#include <array>
#include <string>
#include <utility>

namespace clspv {

enum class FeatureMacro {
  error,
  __opencl_c_3d_image_writes,
  __opencl_c_atomic_order_acq_rel,
  __opencl_c_fp64,
  __opencl_c_images,
  __opencl_c_subgroups,
  // following items are not supported
  __opencl_c_device_enqueue,
  __opencl_c_pipes,
  __opencl_c_program_scope_global_variables,
  // following items are always enabled, but no point in complaining if they are
  // also enabled by the user.
  // int64 is assumed defined for FULL profile
  // https://github.com/llvm/llvm-project/blob/main/clang/lib/Frontend/InitPreprocessor.cpp
  __opencl_c_int64,
  // Some macros are already defined for OpenCL C 3.0 with SPIR-V -
  // https://github.com/llvm/llvm-project/blob/main/clang/lib/Headers/opencl-c-base.h
  __opencl_c_atomic_order_seq_cst,
  __opencl_c_read_write_images,
  __opencl_c_atomic_scope_device,
  __opencl_c_atomic_scope_all_devices,
  __opencl_c_generic_address_space,
  __opencl_c_work_group_collective_functions,
  // dot product
  __opencl_c_integer_dot_product_input_4x8bit,
  __opencl_c_integer_dot_product_input_4x8bit_packed,
};

#define FeatureStr(f) std::make_pair(FeatureMacro::f, #f)
constexpr std::array<std::pair<FeatureMacro, const char *>, 17>
    FeatureMacroList{
        FeatureStr(__opencl_c_3d_image_writes),
        FeatureStr(__opencl_c_atomic_order_acq_rel),
        FeatureStr(__opencl_c_fp64), FeatureStr(__opencl_c_images),
        FeatureStr(__opencl_c_generic_address_space),
        FeatureStr(__opencl_c_subgroups),
        // following items are always enabled by clang
        FeatureStr(__opencl_c_int64),
        FeatureStr(__opencl_c_atomic_order_seq_cst),
        FeatureStr(__opencl_c_read_write_images),
        FeatureStr(__opencl_c_atomic_scope_device),
        FeatureStr(__opencl_c_atomic_scope_all_devices),
        FeatureStr(__opencl_c_work_group_collective_functions),
        // following items cannot be enabled so are automatically disabled
        FeatureStr(__opencl_c_device_enqueue), FeatureStr(__opencl_c_pipes),
        FeatureStr(__opencl_c_program_scope_global_variables),
        FeatureStr(__opencl_c_integer_dot_product_input_4x8bit),
        FeatureStr(__opencl_c_integer_dot_product_input_4x8bit_packed),
    };
#undef FeatureStr

FeatureMacro FeatureMacroLookup(const std::string &name);
} // namespace clspv

#endif // CLSPV_LIB_FEATUREMACRO_H
