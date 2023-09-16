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

#include "FeatureMacro.h"

#include <cstdint>
#include <set>

namespace clspv {

namespace Builtins {
enum BuiltinType : unsigned int;
}

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

// Returns true if clamp should be on 32bit elements when performing staturating
// operations. Works around a driver bug.
bool HackClampWidth();

// Returns true if OpSMulExtended and OpUMulExtended should be avoided. Works
// around a driver bug.
bool HackMulExtended();

// Returns true if ptrtoint on logical address spaces should be emulated using
// compile-time constants when it is safe to do so.
bool HackLogicalPtrtoint();

// Returns true if a dummy instruction should be inserted after conversion to
// float to prevent driver optimisation getting rid of the conversion.
bool HackConvertToFloat();

// Returns true if reading a image1d_buffer with CL_BGRA format without sampler
// requires components to be shuffled to match OpenCL specification.
bool HackImage1dBufferBGRA();

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
uint32_t MaxUniformBufferSize();

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

// Returns true if clspv should allow 8-bit integers.
bool Int8Support();

// Returns true if we should apply a workaround to make the alignment of packed structs
// that were passed as a storage buffer match with the wrapper runtime array
// stride.
bool RewritePackedStructs();

// Returns true if clspv should lower long-vector types and instructions.
bool LongVectorSupport();

// Returns true when images are supported.
bool ImageSupport();

// Returns a list of builtin functions (represented by their BuiltinType) that
// we should generate natively (with an equivalent GLSL extended or core SPIR-V
// instruction) rather than using the builtin library implementation.
std::set<clspv::Builtins::BuiltinType> UseNativeBuiltins();

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

std::set<FeatureMacro> EnabledFeatureMacros();

// Returns true when the source language makes use of the generic address space.
inline bool LanguageUsesGenericAddressSpace() {
  return (Language() == SourceLanguage::OpenCL_CPP) ||
         (Language() == SourceLanguage::OpenCL_C_20) ||
         (Language() == SourceLanguage::OpenCL_C_30 &&
          EnabledFeatureMacros().count(
              clspv::FeatureMacro::__opencl_c_generic_address_space) > 0);
}

enum class RoundingModeRTE : uint32_t {
  fp16,
  fp32,
  fp64,
};

// Returns true when the execution mode RoundingModeRTE should be set for a
// floating point type.
bool ExecutionModeRoundingModeRTE(RoundingModeRTE rm);

// Return the SPIR-V binary version
enum class SPIRVVersion : uint32_t {
  SPIRV_1_0 = 0,
  // No SPIR-V 1.1 or 1.2 because they add purely OpenCL features.
  SPIRV_1_3,
  SPIRV_1_4,
  SPIRV_1_5,
  SPIRV_1_6,
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

// Returns true if unsafe math optimizations are allowed.
// The following options imply this flag:
// * -cl-unsafe-math-optimizations
// * -cl-fast-relaxed-math
// * -cl-native-math
bool UnsafeMath();

// Returns true if finite math is assumed.
// The following options imply this flag:
// * -cl-finite-math-only
// * -cl-fast-relaxed-math
// * -cl-native-math
bool FiniteMath();

// Returns true if fast relaxed math is enabled.
// The following options imply this flag:
// * -cl-fast-relaxed-math
// * -cl-native-math
bool FastRelaxedMath();

// Returns true if -cl-native-math is enabled.
bool NativeMath();

// Returns true if cl_khr_fp16 is enabled
bool FP16();

// Returns true if FP64 support is enabled
bool FP64();

// Returns true if cl_arm_non_uniform_work_group_size is enabled
bool ArmNonUniformWorkGroupSize();

// Returns true if uniform_workgroup_size is enabled
bool UniformWorkgroupSize();

// Returns true if kernel argument info production is enabled
bool KernelArgInfo();

enum class Vec3ToVec4SupportClass : int {
  vec3ToVec4SupportDefault = 0,
  vec3ToVec4SupportError,   // -vec3-to-vec4 & -no-vec3-to-vec4
  vec3ToVec4SupportForce,   // -vec3-to-vec4
  vec3ToVec4SupportDisable, // -no-vec3-to-vec4
};

Vec3ToVec4SupportClass Vec3ToVec4();

// Returns true if opaque pointers are enabled
bool OpaquePointers();

// Returns true if the debug information should be generated
bool DebugInfo();

// Returns true if the NonUniform pointers need to be decorated with the
// NonUniform decoration.
bool DecorateNonUniform();

// Returns true if physical storage buffers are used instead of regular storage
// buffers
bool PhysicalStorageBuffers();

// Returns true if printf support is enabled
bool PrintfSupport();

// Returns the size of the printf buffer in bytes. The default value is 1MB.
uint32_t PrintfBufferSize();

} // namespace Option
} // namespace clspv

#endif // CLSPV_INCLUDE_CLSPV_OPTION_H_
