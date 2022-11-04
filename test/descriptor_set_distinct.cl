// RUN: clspv %target %s -o %t.spv -cluster-pod-kernel-args -distinct-kernel-descriptor-sets
// RUN: clspv-reflection %t.spv -o %t.map
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv



// MAP: kernel,foo,arg,A,argOrdinal,0,descriptorSet,0,binding,0,offset,0
// MAP: kernel,foo,arg,n,argOrdinal,1,offset,0
// MAP: kernel,foo,arg,c,argOrdinal,2,offset,16

// MAP: kernel,bar,arg,B,argOrdinal,0,descriptorSet,1,binding,0,offset,0
// MAP: kernel,bar,arg,m,argOrdinal,1,offset,0
// MAP-NOT: kernel


void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* A, uint n, float4 c)
{
  A[n] = c.x;
}

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) bar(global float* B, uint m)
{
  B[m] *= 2.0;
}
