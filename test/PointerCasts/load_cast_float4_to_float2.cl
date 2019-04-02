// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv
















void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float2* a, global float4* b, int i)
{
  *a = ((global float2*)b)[i];
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 37
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_24:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_24]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_v2float:%[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK:  OpMemberDecorate [[__struct_4:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_4]] Block
// CHECK:  OpDecorate [[__runtimearr_v4float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK:  OpMemberDecorate [[__struct_8:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_8]] Block
// CHECK:  OpMemberDecorate [[__struct_11:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_11]] Block
// CHECK:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_21]] Binding 0
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_22]] Binding 1
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_23]] Binding 2
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK:  [[__runtimearr_v2float]] = OpTypeRuntimeArray [[_v2float]]
// CHECK:  [[__struct_4]] = OpTypeStruct [[__runtimearr_v2float]]
// CHECK:  [[__ptr_StorageBuffer__struct_4:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK:  [[__struct_8]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK:  [[__ptr_StorageBuffer__struct_8:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_8]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__struct_11]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_11:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_11]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_14:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_v2float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v2float]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_21]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK:  [[_22]] = OpVariable [[__ptr_StorageBuffer__struct_8]] StorageBuffer
// CHECK:  [[_23]] = OpVariable [[__ptr_StorageBuffer__struct_11]] StorageBuffer
// CHECK:  [[_24]] = OpFunction [[_void]] None [[_14]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_21]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_23]] [[_uint_0]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_27]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpShiftRightLogical [[_uint]] [[_28]] [[_uint_1]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_22]] [[_uint_0]] [[_29]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_30]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_28]] [[_uint_1]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_32]] [[_uint_1]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpVectorExtractDynamic [[_float]] [[_31]] [[_33]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_33]] [[_uint_1]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpVectorExtractDynamic [[_float]] [[_31]] [[_36]]
// CHECK:  [[construct:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2float]] [[_34]] [[_37]]
// CHECK:  OpStore [[_26]] [[construct]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
