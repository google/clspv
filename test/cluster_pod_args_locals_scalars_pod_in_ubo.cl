// RUN: clspv %s -o %t.spv -cluster-pod-kernel-args -pod-ubo -descriptormap=%t2.map
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
// MAP-NEXT: kernel,foo,arg,f,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,pod_ubo,argSize,4
// MAP-NEXT: kernel,foo,arg,n,argOrdinal,3,descriptorSet,0,binding,1,offset,4,argKind,pod_ubo,argSize,4
// MAP-NOT: kernel


// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Bound: 31
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_22:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpExecutionMode [[_22]] LocalSize 1 1 1
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_9]] Block
// CHECK: OpMemberDecorate [[__struct_10:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[__struct_10]] 1 Offset 4
// CHECK: OpMemberDecorate [[__struct_11:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_11]] Block
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
// CHECK-DAG: [[__struct_10]] = OpTypeStruct [[_float]] [[_uint]]
// CHECK-DAG: [[__struct_11]] = OpTypeStruct [[__struct_10]]
// CHECK-DAG: [[__ptr_Uniform_struct_11:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[__struct_11]]
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_17:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[__ptr_Uniform_struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[__struct_10]]
// CHECK-DAG: [[__ptr_Workgroup_float:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_float]]
// CHECK: [[_2]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG: [[__arr_float_2:%[0-9a-zA-Z_]+]] = OpTypeArray [[_float]] [[_2]]
// CHECK-DAG: [[__ptr_Workgroup__arr_float_2:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr_float_2]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_19:%[0-9a-zA-Z]+]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK: [[_20:%[0-9a-zA-Z]+]] = OpVariable [[__ptr_Uniform_struct_11]] Uniform
// CHECK: [[_1:%[0-9a-zA-Z]+]] = OpVariable [[__ptr_Workgroup__arr_float_2]] Workgroup
// CHECK: [[_21:%[0-9a-zA-Z]+]] = OpFunction [[_void]] None [[_17]]
// CHECK: [[_22:%[0-9a-zA-Z]+]] =	OpLabel
// CHECK: [[_23:%[0-9a-zA-Z]+]] = OpAccessChain [[__ptr_Uniform_struct_10]] [[_20]] [[_uint_0]]
// CHECK: [[_24:%[0-9a-zA-Z]+]] = OpLoad [[__struct_10]] [[_23]]
// CHECK: [[_25:%[0-9a-zA-Z]+]] = OpCompositeExtract [[_float]] [[_24]] 0
// CHECK: [[_26:%[0-9a-zA-Z]+]] = OpCompositeExtract [[_uint]] [[_24]] 1
// CHECK: [[_27:%[0-9a-zA-Z]+]] = OpAccessChain [[__ptr_Workgroup_float]] [[_1]] [[_26]]
// CHECK: [[_28:%[0-9a-zA-Z]+]] = OpLoad [[_float]] [[_27]]
// CHECK: [[_29:%[0-9a-zA-Z]+]] = OpFAdd [[_float]] [[_25]] [[_28]]
// CHECK: [[_30:%[0-9a-zA-Z]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_19]] [[_uint_0]] [[_26]]
// CHECK: 	OpStore [[_30]] [[_29]]
// CHECK: 	OpReturn
// CHECK: 	OpFunctionEnd
