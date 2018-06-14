// RUN: clspv %s -S -o %t.spvasm -cluster-pod-kernel-args -descriptormap=%t.map
// RUN: FileCheck %s < %t.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: clspv %s -o %t.spv -cluster-pod-kernel-args -descriptormap=%t.map
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// MAP: kernel,foo,arg,A,argOrdinal,0,descriptorSet,0,binding,0,offset,0
// MAP: kernel,foo,arg,n,argOrdinal,1,descriptorSet,0,binding,1,offset,0
// MAP: kernel,foo,arg,c,argOrdinal,2,descriptorSet,0,binding,1,offset,16


// CHECK: OpMemberDecorate [[first_struct:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[first_struct]] Block
// CHECK: OpMemberDecorate [[podty:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[podty]] 1 Offset 16
// CHECK: OpMemberDecorate [[st_podty:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[st_podty]] Block

// CHECK: OpDecorate [[Aarg:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[Aarg]] Binding 0
// CHECK: OpDecorate [[podargs:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[podargs]] Binding 1

// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[float4:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]]
// CHECK-DAG: [[podty]] = OpTypeStruct [[uint]] [[float4]]
// CHECK-DAG: [[st_podty]] = OpTypeStruct [[podty]]
// CHECK-DAG: [[sbptr_st_podty:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[st_podty]]
// CHECK-DAG: [[sbptr_podty:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[podty]]

// CHECK: [[podargs]] = OpVariable [[sbptr_st_podty]] StorageBuffer

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* A, uint n, float4 c)
{
  A[n] = c.x;
}
