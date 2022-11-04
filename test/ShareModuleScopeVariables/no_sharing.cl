// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

int helper(local int* A, int idx) { return A[idx]; }

kernel void foo(global int *in, global int* out, int n) {
  local int tmp1[32];
  local int tmp2[32];
  tmp1[n] = in[n];
  barrier(CLK_LOCAL_MEM_FENCE);
  tmp2[n] = helper(tmp1, n);
  barrier(CLK_LOCAL_MEM_FENCE);
  out[n] = helper(tmp2, n);
}

// CHECK-NOT: OpVariable {{.*}} Workgroup
// CHECK: OpVariable {{.*}} Workgroup
// CHECK: OpVariable {{.*}} Workgroup
// CHECK-NOT: OpVariable {{.*}} Workgroup

