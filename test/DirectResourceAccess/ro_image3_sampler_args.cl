// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Just for fun, swap arguments in the helpers.

float4 core(read_only image3d_t im, float4 coord, sampler_t s) {
  return read_imagef(im, s, coord);
}

void apple(read_only image3d_t im, sampler_t s, float4 coord, global float4 *A) {
    *A = core(im, coord, s); }

kernel void foo(float4 coord, sampler_t s, read_only image3d_t im, global float4* A) {
    apple(im, s, 2 * coord, A); }
kernel void bar(float4 coord, sampler_t s, read_only image3d_t im, global float4* A) {
    apple(im, s, 3 * coord, A); }
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 73
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_55:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_64:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_27:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_28:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_29:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpDecorate [[__runtimearr_v4float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK:  OpMemberDecorate [[__struct_8:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_8]] Block
// CHECK:  OpMemberDecorate [[__struct_10:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_10]] Block
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_32:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_32]] Binding 1
// CHECK:  OpDecorate [[_33:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_33]] Binding 2
// CHECK:  OpDecorate [[_33]] NonWritable
// CHECK:  OpDecorate [[_34:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_34]] Binding 3
// CHECK:  OpDecorate [[_35:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_35]] Binding 0
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_2:%[0-9a-zA-Z_]+]] = OpTypeSampler
// CHECK:  [[__ptr_UniformConstant_2:%[0-9a-zA-Z_]+]] = OpTypePointer UniformConstant [[_2]]
// CHECK:  [[_4:%[0-9a-zA-Z_]+]] = OpTypeImage [[_float]] 3D 0 0 0 1 Unknown
// CHECK:  [[__ptr_UniformConstant_4:%[0-9a-zA-Z_]+]] = OpTypePointer UniformConstant [[_4]]
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK:  [[__struct_8]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK:  [[__ptr_StorageBuffer__struct_8:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_8]]
// CHECK:  [[__struct_10]] = OpTypeStruct [[_v4float]]
// CHECK:  [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_13:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK:  [[_16:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_v4float]] [[_4]] [[_v4float]] [[_2]]
// CHECK:  [[_17:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]] [[_4]] [[_2]] [[_v4float]] [[__ptr_StorageBuffer_v4float]]
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[_20:%[0-9a-zA-Z_]+]] = OpTypeSampledImage [[_4]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_float_2:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 2
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v4float]] [[_float_2]] [[_float_2]] [[_float_2]] [[_float_2]]
// CHECK:  [[_float_3:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 3
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v4float]] [[_float_3]] [[_float_3]] [[_float_3]] [[_float_3]]
// CHECK:  [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK:  [[_27]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_28]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_29]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_27]] [[_28]] [[_29]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_32]] = OpVariable [[__ptr_UniformConstant_2]] UniformConstant
// CHECK:  [[_33]] = OpVariable [[__ptr_UniformConstant_4]] UniformConstant
// CHECK:  [[_34]] = OpVariable [[__ptr_StorageBuffer__struct_8]] StorageBuffer
// CHECK:  [[_35]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpFunction [[_v4float]] Pure [[_16]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_4]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_v4float]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_2]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpLoad [[_2]] [[_32]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpLoad [[_4]] [[_33]]
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpSampledImage [[_20]] [[_42]] [[_41]]
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpImageSampleExplicitLod [[_v4float]] [[_43]] [[_38]] Lod [[_float_0]]
// CHECK:  OpReturnValue [[_44]]
// CHECK:  OpFunctionEnd
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpFunction [[_void]] None [[_17]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_4]]
// CHECK:  [[_47:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_2]]
// CHECK:  [[_48:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_v4float]]
// CHECK:  [[_49:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_v4float]]
// CHECK:  [[_50:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_51:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_34]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_52:%[0-9a-zA-Z_]+]] = OpLoad [[_2]] [[_32]]
// CHECK:  [[_53:%[0-9a-zA-Z_]+]] = OpLoad [[_4]] [[_33]]
// CHECK:  [[_54:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_v4float]] [[_36]] [[_53]] [[_48]] [[_52]]
// CHECK:  OpStore [[_51]] [[_54]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_55]] = OpFunction [[_void]] None [[_13]]
// CHECK:  [[_56:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_57:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_35]] [[_uint_0]]
// CHECK:  [[_58:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_57]]
// CHECK:  [[_59:%[0-9a-zA-Z_]+]] = OpLoad [[_2]] [[_32]]
// CHECK:  [[_60:%[0-9a-zA-Z_]+]] = OpLoad [[_4]] [[_33]]
// CHECK:  [[_61:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_34]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_62:%[0-9a-zA-Z_]+]] = OpFMul [[_v4float]] [[_58]] [[_23]]
// CHECK:  [[_63:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_45]] [[_60]] [[_59]] [[_62]] [[_61]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_64]] = OpFunction [[_void]] None [[_13]]
// CHECK:  [[_65:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_66:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_35]] [[_uint_0]]
// CHECK:  [[_67:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_66]]
// CHECK:  [[_68:%[0-9a-zA-Z_]+]] = OpLoad [[_2]] [[_32]]
// CHECK:  [[_69:%[0-9a-zA-Z_]+]] = OpLoad [[_4]] [[_33]]
// CHECK:  [[_70:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_34]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_71:%[0-9a-zA-Z_]+]] = OpFMul [[_v4float]] [[_67]] [[_25]]
// CHECK:  [[_72:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_45]] [[_69]] [[_68]] [[_71]] [[_70]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
