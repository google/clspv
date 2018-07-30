// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv














float4 bar(sampler_t s, read_only image3d_t i, float4 c)
{
  return read_imagef(i, s, c);
}


void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(sampler_t s, read_only image3d_t i, float4 c, global float4* a)
{
  *a = bar(s, i, c);
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 41
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_33:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_33]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_7]] Block
// CHECK:  OpDecorate [[__runtimearr_v4float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK:  OpMemberDecorate [[__struct_10:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_10]] Block
// CHECK:  OpDecorate [[_20:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_20]] Binding 0
// CHECK:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_21]] Binding 1
// CHECK:  OpDecorate [[_21]] NonWritable
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_22]] Binding 2
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_23]] Binding 3
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_2:%[0-9a-zA-Z_]+]] = OpTypeSampler
// CHECK:  [[__ptr_UniformConstant_2:%[0-9a-zA-Z_]+]] = OpTypePointer UniformConstant [[_2]]
// CHECK:  [[_4:%[0-9a-zA-Z_]+]] = OpTypeImage [[_float]] 3D 0 0 0 1 Unknown
// CHECK:  [[__ptr_UniformConstant_4:%[0-9a-zA-Z_]+]] = OpTypePointer UniformConstant [[_4]]
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[__struct_7]] = OpTypeStruct [[_v4float]]
// CHECK:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK:  [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK:  [[__struct_10]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK:  [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_13:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK:  [[_16:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_v4float]] [[_2]] [[_4]] [[_v4float]]
// CHECK:  [[_17:%[0-9a-zA-Z_]+]] = OpTypeSampledImage [[_4]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK:  [[_20]] = OpVariable [[__ptr_UniformConstant_2]] UniformConstant
// CHECK:  [[_21]] = OpVariable [[__ptr_UniformConstant_4]] UniformConstant
// CHECK:  [[_22]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK:  [[_23]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpFunction [[_v4float]] Pure [[_16]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_2]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_4]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_v4float]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpLoad [[_4]] [[_21]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpLoad [[_2]] [[_20]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpSampledImage [[_17]] [[_29]] [[_30]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpImageSampleExplicitLod [[_v4float]] [[_31]] [[_27]] Lod [[_float_0]]
// CHECK:  OpReturnValue [[_32]]
// CHECK:  OpFunctionEnd
// CHECK:  [[_33]] = OpFunction [[_void]] None [[_13]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpLoad [[_2]] [[_20]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpLoad [[_4]] [[_21]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_22]] [[_uint_0]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_37]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_23]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_v4float]] [[_24]] [[_35]] [[_36]] [[_38]]
// CHECK:  OpStore [[_39]] [[_40]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
