// RUN: clspv %target %s -o %t.spv -cluster-pod-kernel-args
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
// MAP-NEXT: kernel,foo,arg,f,argOrdinal,1,offset,0,argKind,pod_pushconstant,argSize,4
// MAP-NEXT: kernel,foo,arg,n,argOrdinal,3,offset,4,argKind,pod_pushconstant,argSize,4
// MAP-NOT: kernel

// CHECK: OpDecorate [[_20:%[0-9a-zA-Z_]+]] Binding 0
// CHECK: OpDecorate [[_2:%[0-9a-zA-Z_]+]] SpecId 3
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[__struct_12:%[0-9a-zA-Z_]+]] = OpTypeStruct [[_float]] [[_uint]]
// CHECK: [[__struct_13:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__struct_12]]
// CHECK: [[__ptr_PushConstant__struct_13:%[0-9a-zA-Z_]+]] = OpTypePointer PushConstant [[__struct_13]]
// CHECK: [[_2]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_20]] = OpVariable {{.*}} StorageBuffer
// CHECK: [[_21:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_PushConstant__struct_13]] PushConstant
// CHECK: OpVariable {{.*}} Workgroup
