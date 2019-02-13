// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv
















void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int3* a, global float3* b, int i)
{
  *a = ((global int3*)b)[i];
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 30
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_22:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_22]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_v3uint:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK:  OpMemberDecorate [[__struct_4:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_4]] Block
// CHECK:  OpDecorate [[__runtimearr_v3float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK:  OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_9]] Block
// CHECK:  OpMemberDecorate [[__struct_11:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_11]] Block
// CHECK:  OpDecorate [[_19:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_19]] Binding 0
// CHECK:  OpDecorate [[_20:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_20]] Binding 1
// CHECK:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_21]] Binding 2
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__runtimearr_v3uint]] = OpTypeRuntimeArray [[_v3uint]]
// CHECK:  [[__struct_4]] = OpTypeStruct [[__runtimearr_v3uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_4:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_v3float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 3
// CHECK:  [[__runtimearr_v3float]] = OpTypeRuntimeArray [[_v3float]]
// CHECK:  [[__struct_9]] = OpTypeStruct [[__runtimearr_v3float]]
// CHECK:  [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK:  [[__struct_11]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_11:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_11]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_14:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v3uint]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[__ptr_StorageBuffer_v3float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v3float]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_19]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK:  [[_20]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK:  [[_21]] = OpVariable [[__ptr_StorageBuffer__struct_11]] StorageBuffer
// CHECK:  [[_22]] = OpFunction [[_void]] None [[_14]]
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v3uint]] [[_19]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_21]] [[_uint_0]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_25]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v3float]] [[_20]] [[_uint_0]] [[_26]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_v3float]] [[_27]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpBitcast [[_v3uint]] [[_28]]
// CHECK:  OpStore [[_24]] [[_29]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
