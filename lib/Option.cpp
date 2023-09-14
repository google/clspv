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

// This translation unit defines all Clspv command line option variables.

#include "llvm/PassRegistry.h"

#include "Builtins.h"
#include "BuiltinsEnum.h"
#include "Passes.h"
#include "clspv/Option.h"

#include <sstream>

namespace {

struct BuiltinOptionParserInfo {
  using OptionEnum = clspv::Builtins::BuiltinType;
  constexpr static OptionEnum ErrorValue = OptionEnum::kBuiltinNone;
  constexpr static OptionEnum (*Lookup)(const std::string &) =
      clspv::Builtins::LookupBuiltinType;
};

struct FeatureMacroOptionParserInfo {
  using OptionEnum = clspv::FeatureMacro;
  constexpr static OptionEnum ErrorValue = clspv::FeatureMacro::error;
  constexpr static OptionEnum (*Lookup)(const std::string &) =
      clspv::FeatureMacroLookup;
};

// Custom parser for parsing a comma separated list of builtin functions into a
// std::set containing the equivalent list of BuiltinType enums. We use a
// custom parser with a regular cl::opt instead of a cl::list because cl::list
// requires you to list all possible choices (in this case all builtin
// functions) and then includes all those choices in the helptext for the flag.
template <typename OptionParserInfo>
struct HiddenOptionListParser
    : public llvm::cl::parser<std::set<typename OptionParserInfo::OptionEnum>> {
  HiddenOptionListParser(llvm::cl::Option &opt)
      : llvm::cl::parser<std::set<typename OptionParserInfo::OptionEnum>>(
            opt){};
  bool parse(llvm::cl::Option &opt, llvm::StringRef,
             const llvm::StringRef &ArgValue,
             std::set<typename OptionParserInfo::OptionEnum> &Val) {
    std::stringstream argValStream(ArgValue.str());
    while (argValStream.good()) {
      std::string substr;
      std::getline(argValStream, substr, ',');
      // A trailing comma will result in our last string being empty
      if (substr.empty()) {
        break;
      }
      auto typeEnum = OptionParserInfo::Lookup(substr);
      if (typeEnum == OptionParserInfo::ErrorValue) {
        // We got a function name that we don't recognize as a builtin.
        return opt.error("'" + substr + "' wasn't recognized as an option!");
      }
      Val.insert(typeEnum);
    }

    // Implementations of parse() are expected to return false on success.
    return false;
  }
};

llvm::cl::opt<bool>
    inline_entry_points("inline-entry-points", llvm::cl::init(false),
                        llvm::cl::desc("Exhaustively inline entry points."));

llvm::cl::opt<bool> no_inline_single_call_site(
    "no-inline-single", llvm::cl::init(false),
    llvm::cl::desc("Disable inlining functions with single call sites."));

// Should the compiler try to use direct resource accesses within helper
// functions instead of passing pointers via function arguments?
llvm::cl::opt<bool> no_direct_resource_access(
    "no-dra", llvm::cl::init(false),
    llvm::cl::desc(
        "No Direct Resource Access: Avoid rewriting helper functions "
        "to access resources directly instead of by pointers "
        "in function arguments.  Affects kernel arguments of type "
        "pointer-to-global, pointer-to-constant, image, and sampler."));

llvm::cl::opt<bool> no_share_module_scope_variables(
    "no-smsv", llvm::cl::init(false),
    llvm::cl::desc("No Share Module Scope Variables: Avoid de-duplicating "
                   "module scope variables."));

// By default, reuse the same descriptor set number for all arguments.
// To turn that off, use -distinct-kernel-descriptor-sets
llvm::cl::opt<bool> distinct_kernel_descriptor_sets(
    "distinct-kernel-descriptor-sets", llvm::cl::init(false),
    llvm::cl::desc("Each kernel uses its own descriptor set for its arguments. "
                   "Turns off direct-resource-access optimizations."));

llvm::cl::opt<bool> hack_initializers(
    "hack-initializers", llvm::cl::init(false),
    llvm::cl::desc(
        "At the start of each kernel, explicitly write the initializer "
        "value for a compiler-generated variable containing the workgroup "
        "size. Required by some drivers to make the get_global_size builtin "
        "function work when used with non-constant dimension index."));

llvm::cl::opt<bool> hack_dis(
    "hack-dis", llvm::cl::init(false),
    llvm::cl::desc("Force use of a distinct image or sampler variable for each "
                   "image or sampler kernel argument.  This prevents sharing "
                   "of resource variables."));

llvm::cl::opt<bool> hack_inserts(
    "hack-inserts", llvm::cl::init(false),
    llvm::cl::desc(
        "Avoid all single-index OpCompositInsert instructions "
        "into struct types by using complete composite construction and "
        "extractions"));

llvm::cl::opt<bool> rewrite_packed_structs(
    "rewrite-packed-structs", llvm::cl::init(false),
    llvm::cl::desc(
        "Rewrite packed structs passed as buffers to a new packed structs with "
        "an array of i8 of equal size to reduce struct alignment"));

llvm::cl::opt<bool> hack_signed_compare_fixup(
    "hack-scf", llvm::cl::init(false),
    llvm::cl::desc("Rewrite signed integer comparisons to use other kinds of "
                   "instructions"));

// Some drivers don't like to see constant composite values constructed
// from scalar Undef values.  Replace numeric scalar and vector Undef with
// corresponding OpConstantNull.  We need to keep Undef for image values,
// for example.  In the LLVM domain, image values are passed as pointer to
// struct.
// See https://github.com/google/clspv/issues/95
llvm::cl::opt<bool> hack_undef(
    "hack-undef", llvm::cl::init(false),
    llvm::cl::desc("Use OpConstantNull instead of OpUndef for floating point, "
                   "integer, or vectors of them"));

llvm::cl::opt<bool> hack_phis(
    "hack-phis", llvm::cl::init(false),
    llvm::cl::desc(
        "Scalarize phi instructions of struct type before code generation"));

llvm::cl::opt<bool> hack_block_order(
    "hack-block-order", llvm::cl::init(false),
    llvm::cl::desc("Order basic blocks using structured order"));

llvm::cl::opt<bool> hack_clamp_width(
    "hack-clamp-width", llvm::cl::init(false),
    llvm::cl::desc("Force clamp to be on 32bit elements at least when "
                   "performing staturating operations"));

llvm::cl::opt<bool> hack_mul_extended(
    "hack-mul-extended", llvm::cl::init(false),
    llvm::cl::desc("Avoid usage of OpSMulExtended and OpUMulExtended"));

llvm::cl::opt<bool> hack_convert_to_float(
    "hack-convert-to-float", llvm::cl::init(false),
    llvm::cl::desc("Insert a dummy instruction after conversions to float to "
                   "avoid driver optimization getting rid of the conversion"));

llvm::cl::opt<bool>
    pod_ubo("pod-ubo", llvm::cl::init(false),
            llvm::cl::desc("POD kernel arguments are in uniform buffers"));

llvm::cl::opt<bool> pod_pushconstant(
    "pod-pushconstant",
    llvm::cl::desc("POD kernel arguments are in the push constant interface"),
    llvm::cl::init(false));

llvm::cl::opt<bool> module_constants_in_storage_buffer(
    "module-constants-in-storage-buffer", llvm::cl::init(false),
    llvm::cl::desc(
        "Module-scope __constants are collected into a single storage buffer.  "
        "The binding and initialization data are reported in the descriptor "
        "map."));

llvm::cl::opt<bool> show_ids("show-ids", llvm::cl::init(false),
                             llvm::cl::desc("Show SPIR-V IDs for functions"));

llvm::cl::opt<bool> constant_args_in_uniform_buffer(
    "constant-args-ubo", llvm::cl::init(false),
    llvm::cl::desc("Put pointer-to-constant kernel args in UBOs."));

// Default to 64kB.
llvm::cl::opt<uint32_t> maximum_ubo_size(
    "max-ubo-size", llvm::cl::init(64 << 10),
    llvm::cl::desc("Specify the maximum UBO array size in bytes."));

llvm::cl::opt<uint32_t> maximum_pushconstant_size(
    "max-pushconstant-size", llvm::cl::init(128),
    llvm::cl::desc(
        "Specify the maximum push constant interface size in bytes."));

llvm::cl::opt<bool> relaxed_ubo_layout(
    "relaxed-ubo-layout",
    llvm::cl::desc("Allow UBO layouts, that do not satisfy the restriction "
                   "that ArrayStride is a multiple of array alignment. This "
                   "does not generate valid SPIR-V for the Vulkan environment; "
                   "however, some drivers may accept it."));

llvm::cl::opt<bool> std430_ubo_layout(
    "std430-ubo-layout", llvm::cl::init(false),
    llvm::cl::desc("Allow UBO layouts that conform to std430 (SSBO) layout "
                   "requirements. This does not generate valid SPIR-V for the "
                   "Vulkan environment; however, some drivers may accept it."));

llvm::cl::opt<bool> int8_support("int8", llvm::cl::init(true),
                                 llvm::cl::desc("Allow 8-bit integers"));

// TODO(#1231): long vector support is required due to sqrt.
llvm::cl::opt<bool> long_vector_support(
    "long-vector", llvm::cl::init(true),
    llvm::cl::desc("Allow vectors of 8 and 16 elements. Experimental"));

llvm::cl::opt<bool> cl_arm_non_uniform_work_group_size(
    "cl-arm-non-uniform-work-group-size", llvm::cl::init(false),
    llvm::cl::desc("Enable the cl_arm_non_uniform_work_group_size extension."));

llvm::cl::opt<clspv::Option::SourceLanguage> cl_std(
    "cl-std", llvm::cl::desc("Select OpenCL standard"),
    llvm::cl::init(clspv::Option::SourceLanguage::OpenCL_C_12),
    llvm::cl::values(clEnumValN(clspv::Option::SourceLanguage::OpenCL_C_10,
                                "CL1.0", "OpenCL C 1.0"),
                     clEnumValN(clspv::Option::SourceLanguage::OpenCL_C_11,
                                "CL1.1", "OpenCL C 1.1"),
                     clEnumValN(clspv::Option::SourceLanguage::OpenCL_C_12,
                                "CL1.2", "OpenCL C 1.2"),
                     clEnumValN(clspv::Option::SourceLanguage::OpenCL_C_20,
                                "CL2.0", "OpenCL C 2.0"),
                     clEnumValN(clspv::Option::SourceLanguage::OpenCL_C_30,
                                "CL3.0", "OpenCL C 3.0"),
                     clEnumValN(clspv::Option::SourceLanguage::OpenCL_CPP,
                                "CLC++", "C++ for OpenCL")));

llvm::cl::opt<clspv::Option::SPIRVVersion> spv_version(
    "spv-version", llvm::cl::desc("Specify the SPIR-V binary version"),
    llvm::cl::init(clspv::Option::SPIRVVersion::SPIRV_1_0),
    llvm::cl::values(
        clEnumValN(clspv::Option::SPIRVVersion::SPIRV_1_0, "1.0",
                   "SPIR-V version 1.0 (Vulkan 1.0)"),
        clEnumValN(clspv::Option::SPIRVVersion::SPIRV_1_3, "1.3",
                   "SPIR-V version 1.3 (Vulkan 1.1). Experimental"),
        clEnumValN(clspv::Option::SPIRVVersion::SPIRV_1_4, "1.4",
                   "SPIR-V version 1.4 (Vulkan 1.1). Experimental"),
        clEnumValN(clspv::Option::SPIRVVersion::SPIRV_1_5, "1.5",
                   "SPIR-V version 1.5 (Vulkan 1.2). Experimental"),
        clEnumValN(clspv::Option::SPIRVVersion::SPIRV_1_6, "1.6",
                   "SPIR-V version 1.6 (Vulkan 1.3). Experimental")));

static llvm::cl::opt<std::set<clspv::FeatureMacro>, false,
                     HiddenOptionListParser<FeatureMacroOptionParserInfo>>
    enabled_feature_macros(
        "enable-feature-macros",
        llvm::cl::desc(
            "Comma separated list of feature macros to enable. Feature "
            "macros not enabled are implicitly disabled. Only "
            "available with CL3.0."));

static llvm::cl::opt<bool> images("images", llvm::cl::init(true),
                                  llvm::cl::desc("Enable support for images"));

static llvm::cl::opt<bool>
    scalar_block_layout("scalar-block-layout", llvm::cl::init(false),
                        llvm::cl::desc("Assume VK_EXT_scalar_block_layout"));

static llvm::cl::opt<bool> work_dim(
    "work-dim", llvm::cl::init(true),
    llvm::cl::desc("Enable support for get_work_dim() built-in function"));

static llvm::cl::opt<bool>
    global_offset("global-offset", llvm::cl::init(false),
                  llvm::cl::desc("Enable support for global offsets"));

static llvm::cl::opt<bool> global_offset_push_constant(
    "global-offset-push-constant", llvm::cl::init(false),
    llvm::cl::desc("Enable support for global offsets in push constants"));

static llvm::cl::opt<bool> cluster_non_pointer_kernel_args(
    "cluster-pod-kernel-args", llvm::cl::init(true),
    llvm::cl::desc("Collect plain-old-data kernel arguments into a struct in "
                   "a single storage buffer, using a binding number after "
                   "other arguments. Use this to reduce storage buffer "
                   "descriptors."));

static llvm::cl::list<clspv::Option::RoundingModeRTE> rounding_mode_rte(
    "rounding-mode-rte",
    llvm::cl::desc(
        "Set execution mode RoundingModeRTE for a floating point type"),
    llvm::cl::CommaSeparated, llvm::cl::ZeroOrMore,
    llvm::cl::values(clEnumValN(clspv::Option::RoundingModeRTE::fp16, "16",
                                "Set execution mode RoundingModeRTE for fp16")),
    llvm::cl::values(clEnumValN(clspv::Option::RoundingModeRTE::fp32, "32",
                                "Set execution mode RoundingModeRTE for fp32")),
    llvm::cl::values(
        clEnumValN(clspv::Option::RoundingModeRTE::fp64, "64",
                   "Set execution mode RoundingModeRTE for fp64")));

static llvm::cl::list<clspv::Option::StorageClass> no_16bit_storage(
    "no-16bit-storage",
    llvm::cl::desc("Disable fine-grained 16-bit storage capabilities."),
    llvm::cl::Prefix, llvm::cl::CommaSeparated, llvm::cl::ZeroOrMore,
    llvm::cl::values(
        clEnumValN(clspv::Option::StorageClass::kSSBO, "ssbo",
                   "Disallow 16-bit types in SSBO interfaces"),
        clEnumValN(clspv::Option::StorageClass::kUBO, "ubo",
                   "Disallow 16-bit types in UBO interfaces"),
        clEnumValN(clspv::Option::StorageClass::kPushConstant, "pushconstant",
                   "Disallow 16-bit types in push constant interfaces")));

static llvm::cl::list<clspv::Option::StorageClass> no_8bit_storage(
    "no-8bit-storage",
    llvm::cl::desc("Disable fine-grained 8-bit storage capabilities."),
    llvm::cl::Prefix, llvm::cl::CommaSeparated, llvm::cl::ZeroOrMore,
    llvm::cl::values(
        clEnumValN(clspv::Option::StorageClass::kSSBO, "ssbo",
                   "Disallow 8-bit types in SSBO interfaces"),
        clEnumValN(clspv::Option::StorageClass::kUBO, "ubo",
                   "Disallow 8-bit types in UBO interfaces"),
        clEnumValN(clspv::Option::StorageClass::kPushConstant, "pushconstant",
                   "Disallow 8-bit types in push constant interfaces")));

static llvm::cl::opt<std::set<clspv::Builtins::BuiltinType>, false,
                     HiddenOptionListParser<BuiltinOptionParserInfo>>
    use_native_builtins(
        "use-native-builtins",
        llvm::cl::desc(
            "Comma separated list of builtin functions that should use "
            "the native implementation instead of the one provided by "
            "the builtin library."));

static llvm::cl::opt<bool> cl_unsafe_math_optimizations(
    "cl-unsafe-math-optimizations", llvm::cl::init(false),
    llvm::cl::desc("Allow optimizations for floating-point arithmetic that (a) "
                   "assume that arguments and results are valid, (b) may "
                   "violate IEEE 754 standard and (c) may violate the OpenCL "
                   "numerical compliance requirements. This option includes "
                   "the -cl-no-signed-zeros and -cl-mad-enable options."));

static llvm::cl::opt<bool> cl_finite_math_only(
    "cl-finite-math-only", llvm::cl::init(false),
    llvm::cl::desc("Allow optimizations for floating-point arithmetic that "
                   "assume that arguments and results are not NaNs or INFs."));

static llvm::cl::opt<bool> cl_fast_relaxed_math(
    "cl-fast-relaxed-math", llvm::cl::init(false),
    llvm::cl::desc("This option causes the preprocessor macro "
                   "__FAST_RELAXED_MATH__ to be defined. Sets the optimization "
                   "options -cl-finite-math-only and "
                   "-cl-unsafe-math-optimizations."));

static llvm::cl::opt<bool> cl_native_math(
    "cl-native-math", llvm::cl::init(false),
    llvm::cl::desc("Perform all math as fast as possible. This option does not "
                   "guarantee that OpenCL precision bounds are maintained. "
                   "Implies -cl-fast-relaxed-math."));

static llvm::cl::opt<bool>
    fp16("fp16", llvm::cl::init(true),
         llvm::cl::desc("Enable support for cl_khr_fp16."));

static llvm::cl::opt<bool>
    fp64("fp64", llvm::cl::init(true),
         llvm::cl::desc(
             "Enable support for FP64 (cl_khr_fp64 and/or __opencl_c_fp64)."));

static llvm::cl::opt<bool> uniform_workgroup_size(
    "uniform-workgroup-size", llvm::cl::init(false),
    llvm::cl::desc("Assume all workgroups are uniformly sized."));

static llvm::cl::opt<bool>
    cl_kernel_arg_info("cl-kernel-arg-info", llvm::cl::init(false),
                       llvm::cl::desc("Produce kernel argument info."));

static llvm::cl::opt<bool>
    force_vec3_to_vec4("vec3-to-vec4", llvm::cl::init(false),
                       llvm::cl::desc("Force lowering vec3 to vec4"));

static llvm::cl::opt<bool>
    force_no_vec3_to_vec4("no-vec3-to-vec4", llvm::cl::init(false),
                          llvm::cl::desc("Force NOT lowering vec3 to vec4"));

static llvm::cl::opt<bool>
    opaque_pointers("enable-opaque-pointers",
                    llvm::cl::desc("Use opaque pointers"),
                    llvm::cl::init(true));

static llvm::cl::opt<bool>
    debug_info("g", llvm::cl::init(false),
               llvm::cl::desc("Produce debug information."));

static llvm::cl::opt<bool> decorate_non_uniform(
    "decorate-nonuniform", llvm::cl::init(false),
    llvm::cl::desc(
        "Decorate NonUniform Pointers with the NonUniform decoration."));

static llvm::cl::opt<bool> physical_storage_buffers(
    "physical-storage-buffers", llvm::cl::init(false),
    llvm::cl::desc("Use physical storage buffers instead of storage buffers"));

static llvm::cl::opt<bool> hack_logical_ptrtoint(
    "hack-logical-ptrtoint", llvm::cl::init(true),
    llvm::cl::desc(
        "Allow ptrtoint on logical address spaces when it can be "
        "guaranteed that they won't be converted back to pointers."));

static llvm::cl::opt<bool>
    printf_support("enable-printf", llvm::cl::desc("Enable support for printf"),
                   llvm::cl::init(false));

static llvm::cl::opt<uint32_t>
    printf_buffer_size("printf-buffer-size",
                       llvm::cl::desc("Size of the printf storage buffer"),
                       llvm::cl::init(1024 << 10));
} // namespace

namespace clspv {
namespace Option {
bool InlineEntryPoints() { return inline_entry_points; }
bool InlineSingleCallSite() { return !no_inline_single_call_site; }
bool DirectResourceAccess() {
  return !(no_direct_resource_access || distinct_kernel_descriptor_sets);
}
bool ShareModuleScopeVariables() { return !no_share_module_scope_variables; }
bool DistinctKernelDescriptorSets() { return distinct_kernel_descriptor_sets; }
bool HackDistinctImageSampler() { return hack_dis; }
bool HackInitializers() { return hack_initializers; }
bool HackInserts() { return hack_inserts; }
bool HackSignedCompareFixup() { return hack_signed_compare_fixup; }
bool HackUndef() { return hack_undef; }
bool HackPhis() { return hack_phis; }
bool HackBlockOrder() { return hack_block_order; }
bool HackClampWidth() { return hack_clamp_width; }
bool HackMulExtended() { return hack_mul_extended; }
bool HackLogicalPtrtoint() { return hack_logical_ptrtoint; }
bool HackConvertToFloat() { return hack_convert_to_float; }
bool ModuleConstantsInStorageBuffer() {
  return module_constants_in_storage_buffer;
}
bool PodArgsInUniformBuffer() { return pod_ubo; }
bool PodArgsInPushConstants() { return pod_pushconstant; }
bool ShowIDs() { return show_ids; }
bool ConstantArgsInUniformBuffer() { return constant_args_in_uniform_buffer; }
uint32_t MaxUniformBufferSize() { return maximum_ubo_size; }
uint32_t MaxPushConstantsSize() { return maximum_pushconstant_size; }
bool RelaxedUniformBufferLayout() { return relaxed_ubo_layout; }
bool Std430UniformBufferLayout() { return std430_ubo_layout; }
bool Int8Support() { return int8_support; }
bool RewritePackedStructs() { return rewrite_packed_structs; }
bool LongVectorSupport() { return long_vector_support; }
bool ImageSupport() { return images; }
SourceLanguage Language() { return cl_std; }
SPIRVVersion SpvVersion() { return spv_version; }
bool ScalarBlockLayout() { return scalar_block_layout; }
bool WorkDim() { return work_dim; }
bool GlobalOffset() { return global_offset; }
bool GlobalOffsetPushConstant() { return global_offset_push_constant; }
bool NonUniformNDRangeSupported() {
  return ((Language() == SourceLanguage::OpenCL_CPP) ||
          (Language() == SourceLanguage::OpenCL_C_20) ||
          (Language() == SourceLanguage::OpenCL_C_30) ||
          ArmNonUniformWorkGroupSize()) &&
         !UniformWorkgroupSize();
}
bool ClusterPodKernelArgs() { return cluster_non_pointer_kernel_args; }

bool ExecutionModeRoundingModeRTE(RoundingModeRTE fp) {
  for (auto type : rounding_mode_rte) {
    if (type == fp) {
      return true;
    }
  }
  return false;
}

bool Supports16BitStorageClass(StorageClass sc) {
  // -no-16bit-storage removes storage capabilities.
  for (auto storage_class : no_16bit_storage) {
    if (storage_class == sc)
      return false;
  }

  return true;
}

bool Supports8BitStorageClass(StorageClass sc) {
  // -no-8bit-storage removes storage capabilities.
  for (auto storage_class : no_8bit_storage) {
    if (storage_class == sc)
      return false;
  }

  return true;
}

bool UnsafeMath() {
  return cl_unsafe_math_optimizations || FastRelaxedMath() || NativeMath();
}
bool FiniteMath() {
  return cl_finite_math_only || FastRelaxedMath() || NativeMath();
}
bool FastRelaxedMath() { return cl_fast_relaxed_math || NativeMath(); }
bool NativeMath() { return cl_native_math; }

std::set<clspv::Builtins::BuiltinType> UseNativeBuiltins() {
  return use_native_builtins;
}

bool FP16() { return fp16; }
bool FP64() { return fp64; }

bool ArmNonUniformWorkGroupSize() { return cl_arm_non_uniform_work_group_size; }
bool UniformWorkgroupSize() { return uniform_workgroup_size; }

bool KernelArgInfo() { return cl_kernel_arg_info; }

Vec3ToVec4SupportClass Vec3ToVec4() {
  if (force_no_vec3_to_vec4 && force_vec3_to_vec4) {
    return Vec3ToVec4SupportClass::vec3ToVec4SupportError;
  } else if (force_vec3_to_vec4) {
    return Vec3ToVec4SupportClass::vec3ToVec4SupportForce;
  } else if (force_no_vec3_to_vec4) {
    return Vec3ToVec4SupportClass::vec3ToVec4SupportDisable;
  } else {
    return Vec3ToVec4SupportClass::vec3ToVec4SupportDefault;
  }
}

bool OpaquePointers() { return opaque_pointers; }

bool DebugInfo() { return debug_info; }

std::set<FeatureMacro> EnabledFeatureMacros() { return enabled_feature_macros; }

bool DecorateNonUniform() { return decorate_non_uniform; }

bool PhysicalStorageBuffers() { return physical_storage_buffers; }

bool PrintfSupport() { return printf_support; }
uint32_t PrintfBufferSize() { return printf_buffer_size; }

} // namespace Option
} // namespace clspv
