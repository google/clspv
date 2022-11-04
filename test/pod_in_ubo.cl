kernel void foo(int k, global int *A, int b) { *A = k + b; }

// RUN: clspv %target %s -o %t.spv -pod-ubo -cluster-pod-kernel-args=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: clspv-reflection %t.spv -o %t.map
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// MAP: kernel,foo,arg,k,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,pod_ubo,argSize,4
// MAP-NEXT: kernel,foo,arg,A,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,b,argOrdinal,2,descriptorSet,0,binding,2,offset,0,argKind,pod_ubo,argSize,4


// CHECK:  OpMemberDecorate [[__struct_2:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_2]] Block
// CHECK:  OpDecorate [[_19:%[0-9a-zA-Z_]+]] Binding 0
// CHECK:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] Binding 2
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__struct_2]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_Uniform__struct_2:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[__struct_2]]
// CHECK:  [[__ptr_Uniform_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[_uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_19]] = OpVariable [[__ptr_Uniform__struct_2]] Uniform
// CHECK:  [[_21]] = OpVariable [[__ptr_Uniform__struct_2]] Uniform
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Uniform_uint]] [[_19]] [[_uint_0]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_24]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Uniform_uint]] [[_21]] [[_uint_0]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_27]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_28]] [[_25]]
// CHECK:  OpStore {{.*}} [[_29]]
