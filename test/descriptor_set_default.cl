// RUN: clspv %s -o %t.spv -cluster-pod-kernel-args -descriptormap=%t.map
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// B reuses the variable for A, and hence its bindings.


// MAP: kernel,foo,arg,A,argOrdinal,0,descriptorSet,0,binding,0,offset,0
// MAP-NEXT: kernel,foo,arg,n,argOrdinal,1,descriptorSet,0,binding,1,offset,0
// MAP-NEXT: kernel,foo,arg,c,argOrdinal,2,descriptorSet,0,binding,1,offset,16

// MAP-NEXT: kernel,bar,arg,B,argOrdinal,0,descriptorSet,0,binding,0,offset,0
// MAP-NEXT: kernel,bar,arg,m,argOrdinal,1,descriptorSet,0,binding,1,offset,0
// MAP-NOT: kernel


void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* A, uint n, float4 c)
{
  A[n] = c.x;
}

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) bar(global float* B, uint m)
{
  B[m] *= 2.0;
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Bound: 39
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_23:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_31:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpExecutionMode [[_23]] LocalSize 1 1 1
// CHECK:  OpExecutionMode [[_31]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpMemberDecorate [[__struct_7]] 1 Offset 16
// CHECK:  OpMemberDecorate [[__struct_8:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_8]] Block
// CHECK:  OpMemberDecorate [[__struct_10:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpMemberDecorate [[__struct_11:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_11]] Block
// CHECK:  OpDecorate [[_20:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_20]] Binding 0
// CHECK:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_21]] Binding 1
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_22]] Binding 1
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK:  [[__struct_3]] = OpTypeStruct [[__runtimearr_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[__struct_7]] = OpTypeStruct [[_uint]] [[_v4float]]
// CHECK:  [[__struct_8]] = OpTypeStruct [[__struct_7]]
// CHECK:  [[__ptr_StorageBuffer__struct_8:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_8]]
// CHECK:  [[__struct_10]] = OpTypeStruct [[_uint]]
// CHECK:  [[__struct_11]] = OpTypeStruct [[__struct_10]]
// CHECK:  [[__ptr_StorageBuffer__struct_11:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_11]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_14:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_float_2:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 2
// CHECK:  [[_20]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_21]] = OpVariable [[__ptr_StorageBuffer__struct_8]] StorageBuffer
// CHECK:  [[_22]] = OpVariable [[__ptr_StorageBuffer__struct_11]] StorageBuffer
// CHECK:  [[_23]] = OpFunction [[_void]] None [[_14]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_7]] [[_21]] [[_uint_0]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpLoad [[__struct_7]] [[_25]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_26]] 0
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_v4float]] [[_26]] 1
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_28]] 0
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_20]] [[_uint_0]] [[_27]]
// CHECK:  OpStore [[_30]] [[_29]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_31]] = OpFunction [[_void]] None [[_14]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_10]] [[_22]] [[_uint_0]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpLoad [[__struct_10]] [[_33]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_34]] 0
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_20]] [[_uint_0]] [[_35]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_36]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpFMul [[_float]] [[_37]] [[_float_2]]
// CHECK:  OpStore [[_36]] [[_38]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
