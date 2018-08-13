// RUN: clspv %s -S -o %t.spvasm -cluster-pod-kernel-args -descriptormap=%t.map
// RUN: FileCheck %s < %t.spvasm
// RUN: FileCheck %s < %t.map -check-prefix=MAP
// RUN: clspv %s -o %t.spv -cluster-pod-kernel-args -descriptormap=%t2.map
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: FileCheck %s < %t2.map -check-prefix=MAP
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* A, float f, local float* B, uint n)
{
  A[n] = B[n] + f;
}


// MAP: kernel,foo,arg,A,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,B,argOrdinal,2,argKind,local,arrayElemSize,4,arrayNumElemSpecId,3
// MAP-NEXT: kernel,foo,arg,f,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,pod
// MAP-NEXT: kernel,foo,arg,n,argOrdinal,3,descriptorSet,0,binding,1,offset,4,argKind,pod
// MAP-NOT: kernel


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
// CHECK: OpEntryPoint GLCompute [[_22:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpExecutionMode [[_22]] LocalSize 1 1 1
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_9]] Block
// CHECK: OpMemberDecorate [[__struct_12:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[__struct_12]] 1 Offset 4
// CHECK: OpMemberDecorate [[__struct_13:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_13]] Block
// CHECK: OpDecorate [[_20:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_20]] Binding 0
// CHECK: OpDecorate [[_21:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_21]] Binding 1
// CHECK: OpDecorate [[_2:%[0-9a-zA-Z_]+]] SpecId 3
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK-DAG: [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK-DAG: [[__struct_9]] = OpTypeStruct [[__runtimearr_float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[__struct_12]] = OpTypeStruct [[_float]] [[_uint]]
// CHECK-DAG: [[__struct_13]] = OpTypeStruct [[__struct_12]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_13:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_13]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_12:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_12]]
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_17:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[__ptr_Workgroup_float:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_float]]
// CHECK: [[_2]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG: [[__arr_float_2:%[0-9a-zA-Z_]+]] = OpTypeArray [[_float]] [[_2]]
// CHECK-DAG: [[__ptr_Workgroup__arr_float_2:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr_float_2]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_20]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK: [[_21]] = OpVariable [[__ptr_StorageBuffer__struct_13]] StorageBuffer
// CHECK: [[_1:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Workgroup__arr_float_2]] Workgroup
// CHECK: [[_22]] = OpFunction [[_void]] None [[_17]]
// CHECK: [[_23:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_24:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_12]] [[_21]] [[_uint_0]]
// CHECK: [[_25:%[0-9a-zA-Z_]+]] = OpLoad [[__struct_12]] [[_24]]
// CHECK: [[_26:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_25]] 0
// CHECK: [[_27:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_25]] 1
// CHECK: [[_28:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_float]] [[_1]] [[_27]]
// CHECK: [[_29:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_28]]
// CHECK: [[_30:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_26]] [[_29]]
// CHECK: [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_20]] [[_uint_0]] [[_27]]
// CHECK: OpStore [[_31]] [[_30]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
