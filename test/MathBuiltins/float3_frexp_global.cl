// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float3* a, global float3* b, global int3* c)
{
  *a = frexp(*b, c);
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 27
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[_1:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_20:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpExecutionMode [[_20]] LocalSize 1 1 1
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[__runtimearr_v3float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK: OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_6]] Block
// CHECK: OpDecorate [[__runtimearr_v3uint:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK: OpMemberDecorate [[__struct_12:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_12]] Block
// CHECK: OpDecorate [[_17:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_17]] Binding 0
// CHECK: OpDecorate [[_18:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_18]] Binding 1
// CHECK: OpDecorate [[_19:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_19]] Binding 2
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v3float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 3
// CHECK-DAG: [[__ptr_StorageBuffer_v3float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v3float]]
// CHECK-DAG: [[__runtimearr_v3float]] = OpTypeRuntimeArray [[_v3float]]
// CHECK-DAG: [[__struct_6]] = OpTypeStruct [[__runtimearr_v3float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_StorageBuffer_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v3uint]]
// CHECK-DAG: [[__runtimearr_v3uint]] = OpTypeRuntimeArray [[_v3uint]]
// CHECK-DAG: [[__struct_12]] = OpTypeStruct [[__runtimearr_v3uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_12:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_12]]
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_15:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_17]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_18]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_19]] = OpVariable [[__ptr_StorageBuffer__struct_12]] StorageBuffer
// CHECK: [[_20]] = OpFunction [[_void]] None [[_15]]
// CHECK: [[_21:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_22:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v3float]] [[_17]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_23:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v3float]] [[_18]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_24:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v3uint]] [[_19]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_25:%[0-9a-zA-Z_]+]] = OpLoad [[_v3float]] [[_23]]
// CHECK: [[_26:%[0-9a-zA-Z_]+]] = OpExtInst [[_v3float]] [[_1]] Frexp [[_25]] [[_24]]
// CHECK: OpStore [[_22]] [[_26]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
