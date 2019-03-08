// RUN: clspv %s -S -o %t.spvasm -no-inline-single -keep-unused-arguments
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv














float4 bar(sampler_t s, read_only image2d_t i, float2 c)
{
  return read_imagef(i, s, c);
}


void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(sampler_t s, read_only image2d_t i, float2 c, global float4* a)
{
  *a = bar(s, i, c);
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 43
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_35:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_35]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_7]] Block
// CHECK:  OpDecorate [[__runtimearr_v4float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK:  OpMemberDecorate [[__struct_11:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_11]] Block
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_22]] Binding 0
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_23]] Binding 1
// CHECK:  OpDecorate [[_24:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_24]] Binding 2
// CHECK:  OpDecorate [[_25:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_25]] Binding 3
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_2:%[0-9a-zA-Z_]+]] = OpTypeSampler
// CHECK:  [[__ptr_UniformConstant_2:%[0-9a-zA-Z_]+]] = OpTypePointer UniformConstant [[_2]]
// CHECK:  [[_4:%[0-9a-zA-Z_]+]] = OpTypeImage [[_float]] 2D 0 0 0 1 Unknown
// CHECK:  [[__ptr_UniformConstant_4:%[0-9a-zA-Z_]+]] = OpTypePointer UniformConstant [[_4]]
// CHECK:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK:  [[__struct_7]] = OpTypeStruct [[_v2float]]
// CHECK:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK:  [[__struct_11]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK:  [[__ptr_StorageBuffer__struct_11:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_11]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_14:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__ptr_StorageBuffer_v2float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v2float]]
// CHECK:  [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK:  [[_18:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_v4float]] [[_2]] [[_4]] [[_v2float]]
// CHECK:  [[_19:%[0-9a-zA-Z_]+]] = OpTypeSampledImage [[_4]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK:  [[_22]] = OpVariable [[__ptr_UniformConstant_2]] UniformConstant
// CHECK:  [[_23]] = OpVariable [[__ptr_UniformConstant_4]] UniformConstant
// CHECK:  [[_24]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK:  [[_25]] = OpVariable [[__ptr_StorageBuffer__struct_11]] StorageBuffer
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpFunction [[_v4float]] Pure [[_18]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_2]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_4]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_v2float]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpLoad [[_4]] [[_23]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpLoad [[_2]] [[_22]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpSampledImage [[_19]] [[_31]] [[_32]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpImageSampleExplicitLod [[_v4float]] [[_33]] [[_29]] Lod [[_float_0]]
// CHECK:  OpReturnValue [[_34]]
// CHECK:  OpFunctionEnd
// CHECK:  [[_35]] = OpFunction [[_void]] None [[_14]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpLoad [[_2]] [[_22]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpLoad [[_4]] [[_23]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_24]] [[_uint_0]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpLoad [[_v2float]] [[_39]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_25]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_v4float]] [[_26]] [[_37]] [[_38]] [[_40]]
// CHECK:  OpStore [[_41]] [[_42]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
