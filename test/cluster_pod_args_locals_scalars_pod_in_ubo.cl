// RUN: clspv %s -o %t.spv -cluster-pod-kernel-args -pod-ubo
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: clspv-reflection %t.spv -o %t2.map
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
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[__struct_10]] = OpTypeStruct [[_float]] [[_uint]]
// CHECK-DAG: [[__struct_11]] = OpTypeStruct [[__struct_10]]
// CHECK-DAG: [[__ptr_Uniform_struct_11:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[__struct_11]]
// CHECK: [[_2]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_20]] = OpVariable {{.*}} StorageBuffer
// CHECK: [[_21]] = OpVariable [[__ptr_Uniform_struct_11]] Uniform
// CHECK: OpVariable {{.*}} Workgroup
