// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float4* b, global int4* c)
{
  int4 temp_c;
  *a = frexp(*b, &temp_c);
  *c = temp_c;
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 31
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: [[_1:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_22:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpExecutionMode [[_22]] LocalSize 1 1 1
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[__runtimearr_v4float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK: OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_6]] Block
// CHECK: OpDecorate [[__runtimearr_v4uint:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK: OpMemberDecorate [[__struct_12:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_12]] Block
// CHECK: OpDecorate [[_19:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_19]] Binding 0
// CHECK: OpDecorate [[_20:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_20]] Binding 1
// CHECK: OpDecorate [[_21:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_21]] Binding 2
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK-DAG: [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK-DAG: [[__struct_6]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK-DAG: [[__ptr_StorageBuffer_v4uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4uint]]
// CHECK-DAG: [[__runtimearr_v4uint]] = OpTypeRuntimeArray [[_v4uint]]
// CHECK-DAG: [[__struct_12]] = OpTypeStruct [[__runtimearr_v4uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_12:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_12]]
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_15:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[__ptr_Function_v4uint:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[_v4uint]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_18:%[0-9a-zA-Z_]+]] = OpConstantNull [[_v4uint]]
// CHECK: [[_19]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_20]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_21]] = OpVariable [[__ptr_StorageBuffer__struct_12]] StorageBuffer
// CHECK: [[_22]] = OpFunction [[_void]] None [[_15]]
// CHECK: [[_23:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_24:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Function_v4uint]] Function
// CHECK: [[_25:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_19]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_26:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_20]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_27:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4uint]] [[_21]] [[_uint_0]] [[_uint_0]]
// CHECK: OpStore [[_24]] [[_18]]
// CHECK: [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_26]]
// CHECK: [[_29:%[0-9a-zA-Z_]+]] = OpExtInst [[_v4float]] [[_1]] Frexp [[_28]] [[_24]]
// CHECK: OpStore [[_25]] [[_29]]
// CHECK: [[_30:%[0-9a-zA-Z_]+]] = OpLoad [[_v4uint]] [[_24]]
// CHECK: OpStore [[_27]] [[_30]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
