// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float2* b)
{
  vstore_half2(*b, 0, (global half *)a);
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 26
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  [[_1:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_19:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_19]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_v4float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK:  OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_5]] Block
// CHECK:  OpDecorate [[__runtimearr_v2float:%[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK:  OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_9]] Block
// CHECK:  OpDecorate [[_17:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_17]] Binding 0
// CHECK:  OpDecorate [[_18:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_18]] Binding 1
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG:  [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK-DAG:  [[__struct_5]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK-DAG:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG:  [[__runtimearr_v2float]] = OpTypeRuntimeArray [[_v2float]]
// CHECK-DAG:  [[__struct_9]] = OpTypeStruct [[__runtimearr_v2float]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_13:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG:  [[__ptr_StorageBuffer_v2float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v2float]]
// CHECK-DAG:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_17]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK:  [[_18]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK:  [[_19]] = OpFunction [[_void]] None [[_13]]
// CHECK:  [[_20:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_18]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpLoad [[_v2float]] [[_21]]
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_1]] PackHalf2x16 [[_22]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_17]] [[_uint_0]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpBitcast [[_float]] [[_23]]
// CHECK:  OpStore [[_24]] [[_25]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
