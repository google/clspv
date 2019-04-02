// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv














void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global int* b, int i)
{
  *b = ((global int*)a)[i];
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 27
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_19:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_19]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_7]] Block
// CHECK:  OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_9]] Block
// CHECK:  OpDecorate [[_16:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_16]] Binding 0
// CHECK:  OpDecorate [[_17:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_17]] Binding 1
// CHECK:  OpDecorate [[_18:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_18]] Binding 2
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK:  [[__struct_3]] = OpTypeStruct [[__runtimearr_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK:  [[__struct_7]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK:  [[__struct_9]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_12:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_16]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_17]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK:  [[_18]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK:  [[_19]] = OpFunction [[_void]] None [[_12]]
// CHECK:  [[_20:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_17]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_18]] [[_uint_0]]
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_22]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_16]] [[_uint_0]] [[_23]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_24]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpBitcast [[_uint]] [[_25]]
// CHECK:  OpStore [[_21]] [[_26]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
