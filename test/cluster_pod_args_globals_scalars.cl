// RUN: clspv %s -S -o %t.spvasm -cluster-pod-kernel-args
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -cluster-pod-kernel-args
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* A, float f, global float* B, uint n)
{
  A[n] = B[n] + f;
}
// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 27
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_17:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpExecutionMode [[_17]] LocalSize 1 1 1
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[__runtimearr_float:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_4:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_4]] Block
// CHECK: OpMemberDecorate [[__struct_7:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[__struct_7]] 1 Offset 4
// CHECK: OpMemberDecorate [[__struct_8:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_8]] Block
// CHECK: OpDecorate [[_14:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_14]] Binding 0
// CHECK: OpDecorate [[_15:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_15]] Binding 1
// CHECK: OpDecorate [[_16:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_16]] Binding 2
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[__ptr_StorageBuffer_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK-DAG: [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK-DAG: [[__struct_4]] = OpTypeStruct [[__runtimearr_float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_4:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK-DAG: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[__struct_7]] = OpTypeStruct [[_float]] [[_uint]]
// CHECK-DAG: [[__struct_8]] = OpTypeStruct [[__struct_7]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_8:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_8]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_7:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK-DAG: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[_12:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_14]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK: [[_15]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK: [[_16]] = OpVariable [[__ptr_StorageBuffer__struct_8]] StorageBuffer
// CHECK: [[_17]] = OpFunction [[_void]] None [[_12]]
// CHECK: [[_18:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_19:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_7]] [[_16]] [[_uint_0]]
// CHECK: [[_20:%[a-zA-Z0-9_]+]] = OpLoad [[__struct_7]] [[_19]]
// CHECK: [[_21:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]] [[_20]] 0
// CHECK: [[_22:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_uint]] [[_20]] 1
// CHECK: [[_23:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_15]] [[_uint_0]] [[_22]]
// CHECK: [[_24:%[a-zA-Z0-9_]+]] = OpLoad [[_float]] [[_23]]
// CHECK: [[_25:%[a-zA-Z0-9_]+]] = OpFAdd [[_float]] [[_21]] [[_24]]
// CHECK: [[_26:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_14]] [[_uint_0]] [[_22]]
// CHECK: OpStore [[_26]] [[_25]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
