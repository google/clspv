// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv














void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int4* a, global float2* b)
{
  *a = *((global int4*)b);
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 29
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_20:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_20]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_v4uint:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK:  OpMemberDecorate [[__struct_4:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_4]] Block
// CHECK:  OpDecorate [[__runtimearr_v2float:%[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK:  OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_9]] Block
// CHECK:  OpDecorate [[_18:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_18]] Binding 0
// CHECK:  OpDecorate [[_19:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_19]] Binding 1
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK:  [[__runtimearr_v4uint]] = OpTypeRuntimeArray [[_v4uint]]
// CHECK:  [[__struct_4]] = OpTypeStruct [[__runtimearr_v4uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_4:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK:  [[__runtimearr_v2float]] = OpTypeRuntimeArray [[_v2float]]
// CHECK:  [[__struct_9]] = OpTypeStruct [[__runtimearr_v2float]]
// CHECK:  [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_12:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_v4uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4uint]]
// CHECK:  [[__ptr_StorageBuffer_v2float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v2float]]
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_18]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK:  [[_19]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK:  [[_20]] = OpFunction [[_void]] None [[_12]]
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4uint]] [[_18]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_19]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpLoad [[_v2float]] [[_23]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_19]] [[_uint_0]] [[_uint_1]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpLoad [[_v2float]] [[_25]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_24]] [[_26]] 0 1 2 3
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpBitcast [[_v4uint]] [[_27]]
// CHECK:  OpStore [[_22]] [[_28]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
