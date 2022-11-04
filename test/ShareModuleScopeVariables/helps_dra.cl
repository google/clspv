// RUN: clspv %target %s -o %t.spv -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

int helper_foo(local int*A, int idx) { return A[idx]; }

int helper(local int* A, int idx) { return helper_foo(A, idx); }

kernel void foo(global int *in, global int *out, int n) {
  local int foo_local[32];
  foo_local[n] = in[n];
  barrier(CLK_LOCAL_MEM_FENCE);
  out[n] = helper(foo_local, n);
}

kernel void bar(global int *in, global int *out, int n) {
  local int bar_local[32];
  bar_local[n+1] = in[n+1];
  barrier(CLK_LOCAL_MEM_FENCE);
  out[n+1] = helper(bar_local, n+1);
}

// foo_local and bar_local should be shared and this should lead to helper_foo
// using the shared variable directly.

// CHECK-NOT: OpVariable {{.*}} Workgroup
// CHECK: [[shared:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} Workgroup
// CHECK-NOT: OpVariable {{.*}} Workgroup
// CHECK: OpFunction
// CHECK: OpAccessChain {{.*}} [[shared]]
// CHECK: OpFunction
// CHECK: OpFunction
