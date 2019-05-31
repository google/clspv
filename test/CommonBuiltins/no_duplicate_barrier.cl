// RUN: clspv %s -o %t
// RUN: spirv-dis %t -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t

// CHECK: OpControlBarrier
// CHECK-NOT: OpControlBarrier

__kernel __attribute__((reqd_work_group_size(16, 1, 1))) void foo(__global int* out) {
  __local int localmem_A[16];

  int lid = get_local_id(0);
  if (lid == 0) {
    localmem_A[lid] = get_group_id(0);
  }

  barrier(CLK_LOCAL_MEM_FENCE);

  if (lid == 0) {
    out[get_group_id(0)] = localmem_A[0];
  }
}
