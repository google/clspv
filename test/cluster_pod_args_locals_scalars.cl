// RUN: clspv %s -S -o %t.spvasm -cluster-pod-kernel-args
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -cluster-pod-kernel-args
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* A, float f, local float* B, uint n)
{
  A[n] = B[n] + f;
}
// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 31
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_21:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpExecutionMode [[_21]] LocalSize 1 1 1
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[__runtimearr_float:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_4:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_4]] Block
// CHECK: OpDecorate [[__runtimearr_float_0:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_8:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_8]] Block
// CHECK: OpMemberDecorate [[__struct_11:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[__struct_11]] 1 Offset 4
// CHECK: OpMemberDecorate [[__struct_12:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_12]] Block
// CHECK: OpDecorate [[_18:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_18]] Binding 0
// CHECK: OpDecorate [[_19:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_19]] Binding 1
// CHECK: OpDecorate [[_20:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_20]] Binding 2
// CHECK: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[__ptr_StorageBuffer_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK: [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK: [[__struct_4]] = OpTypeStruct [[__runtimearr_float]]
// CHECK: [[__ptr_StorageBuffer__struct_4:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK: [[__ptr_Workgroup_float:%[a-zA-Z0-9_]+]] = OpTypePointer Workgroup [[_float]]
// CHECK: [[__runtimearr_float_0]] = OpTypeRuntimeArray [[_float]]
// CHECK: [[__struct_8]] = OpTypeStruct [[__runtimearr_float_0]]
// CHECK: [[__ptr_Workgroup__struct_8:%[a-zA-Z0-9_]+]] = OpTypePointer Workgroup [[__struct_8]]
// CHECK: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[__struct_11]] = OpTypeStruct [[_float]] [[_uint]]
// CHECK: [[__struct_12]] = OpTypeStruct [[__struct_11]]
// CHECK: [[__ptr_StorageBuffer__struct_12:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_12]]
// CHECK: [[__ptr_StorageBuffer__struct_11:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_11]]
// CHECK: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK: [[_16:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CHECK: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_18]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK: [[_19]] = OpVariable [[__ptr_Workgroup__struct_8]] Workgroup
// CHECK: [[_20]] = OpVariable [[__ptr_StorageBuffer__struct_12]] StorageBuffer
// CHECK: [[_21]] = OpFunction [[_void]] None [[_16]]
// CHECK: [[_22:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_23:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_11]] [[_20]] [[_uint_0]]
// CHECK: [[_24:%[a-zA-Z0-9_]+]] = OpLoad [[__struct_11]] [[_23]]
// CHECK: [[_25:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]] [[_24]] 0
// CHECK: [[_26:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_uint]] [[_24]] 1
// CHECK: [[_27:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_Workgroup_float]] [[_19]] [[_uint_0]] [[_26]]
// CHECK: [[_28:%[a-zA-Z0-9_]+]] = OpLoad [[_float]] [[_27]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpFAdd [[_float]] [[_25]] [[_28]]
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_18]] [[_uint_0]] [[_26]]
// CHECK: OpStore [[_30]] [[_29]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
