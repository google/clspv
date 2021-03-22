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

#ifndef CLSPV_INCLUDE_CLSPV_OPTION_H_
#define CLSPV_INCLUDE_CLSPV_OPTION_H_

#include <cstdint>

namespace clspv {
namespace Option {

// Returns true if each kernel must use its own descriptor set for all
// arguments.
bool DistinctKernelDescriptorSets();

// Returns true if the compiler should try to use direct resource accesses
// within helper functions instead of passing pointers via function arguments.
bool DirectResourceAccess();

bool ShareModuleScopeVariables();

// Returns true if we should avoid sharing resource variables for images
// and samplers.  Use this to avoid one difference between the old and new
// descriptor allocation algorithms.
// TODO(dneto): Remove this eventually?
bool HackDistinctImageSampler();

// Returns true if we should apply a workaround to make get_global_size(i)
// with non-constant i work on certain drivers.  The workaround is for the
// value of the workgroup size is written to a special compiler-generated
// variable right at the start of each kernel, rather than relying on the
// variable intializer to take effect.
// TODO(dneto): Remove this eventually when drivers are fixed.
bool HackInitializers();

// Returns true if code generation should avoid single-index OpCompositeInsert
// instructions into struct types.  Use complete OpCompositeConstruct instead.
// TODO(dneto): Remove this eventually when drivers are fixed.
bool HackInserts();

// Returns true if we should rewrite signed integer compares into other
// equivalent code that does not use signed integer comparisons.
// Works around a driver bug.
// TODO(dneto): Remove this eventually when drivers are fixed.
bool HackSignedCompareFixup();

// Returns true if numeric scalar and vector Undef values should be replaced
// with OpConstantNull.  Works around a driver bug.
// TODO(dneto): Remove this eventually when drivers are fixed.
bool HackUndef();

// Returns true if code generation should avoid creating OpPhi of structs.
bool HackPhis();

// Returns true if basic blocks should be in "structured" order.
bool HackBlockOrder();

// Returns true if module-scope constants are to be collected into a single
// storage buffer.  The binding for that buffer, and its intialization data
// are given in the descriptor map file.
bool ModuleConstantsInStorageBuffer();

// Returns true if POD kernel arguments should be passed in via uniform buffers.
bool PodArgsInUniformBuffer();

// Returns true if POD kernel arguments should be passed in via the push
// constant interface.
bool PodArgsInPushConstants();

// Returns true if POD kernel arguments should be clustered into a single
// interface.
bool ClusterPodKernelArgs();

// Returns true if SPIR-V IDs for functions should be emitted to stderr during
// code generation.
bool ShowIDs();

// Returns true if functions with single call sites should be inlined.
bool InlineSingleCallSite();

// Returns true if entry points should be fully inlined.
bool InlineEntryPoints();

// Returns true if pointer-to-constant kernel args should be generated as UBOs.
bool ConstantArgsInUniformBuffer();

// Returns the maximum UBO size. This size is specified in bytes and is used to
// calculate the size of UBO arrays for constant arguments if
// ConstantArgsInUniformBuffer returns true.
uint64_t MaxUniformBufferSize();

// Returns the maximum push constant interface size. This size is specified in
// bytes and is used to validate the the size of the POD kernel interface
// passed as push constants.
uint32_t MaxPushConstantsSize();

// Returns true if clspv should allow UBOs that do not satisfy the restriction
// that ArrayStride is a multiple of array alignment.
bool RelaxedUniformBufferLayout();

// Returns true if clspv should allow UBOs that conform to std430 (SSBO) layout
// requirements.
bool Std430UniformBufferLayout();

// Returns true if clspv should not remove unused arguments of non-kernel
// functions.
bool KeepUnusedArguments();

// Returns true if clspv should allow 8-bit integers.
bool Int8Support();

// Returns true if clspv should lower long-vector types and instructions.
bool LongVectorSupport();

// Returns true when images are supported.
bool ImageSupport();

// Returns true when using a sampler map.
bool UseSamplerMap();

// Sets whether or not to use the sampler map.
void SetUseSamplerMap(bool use);

// Returns the source language.
enum class SourceLanguage {
  Unknown,
  OpenCL_C_10,
  OpenCL_C_11,
  OpenCL_C_12,
  OpenCL_C_20,
  OpenCL_C_30,
  OpenCL_CPP
};

SourceLanguage Language();

// Returns true when the source language makes use of the generic address space.
inline bool LanguageUsesGenericAddressSpace() {
  return (Language() == SourceLanguage::OpenCL_CPP) ||
         ((Language() == SourceLanguage::OpenCL_C_20));
}

// Return the SPIR-V binary version
enum class SPIRVVersion {
  SPIRV_1_0,
  SPIRV_1_3,
  SPIRV_1_5, // note that lack of command line option to specify it
};

SPIRVVersion SpvVersion();

// Returns true when SPV_EXT_scalar_block_layout can be used.
bool ScalarBlockLayout();

// Returns true when support for get_work_dim() is enabled.
bool WorkDim();

// Returns true when support for global offset is enabled.
bool GlobalOffset();

// Returns true when support for global offset is enabled using push constants.
bool GlobalOffsetPushConstant();

// Returns true when support for non uniform NDRanges is enabled.
bool NonUniformNDRangeSupported();

enum class StorageClass : int {
  kSSBO = 0,
  kUBO,
  kPushConstant,
};

// Returns true if |sc| supports 16-bit storage.
bool Supports16BitStorageClass(StorageClass sc);

// Returns true if |sc| supports 8-bit storage.
bool Supports8BitStorageClass(StorageClass sc);

// Returns true if -cl-native-math is enabled.
bool NativeMath();

} // namespace Option
} // namespace clspv

#endif // CLSPV_INCLUDE_CLSPV_OPTION_H_
