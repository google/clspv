// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

int helper(local int* A, int idx) { return A[idx]; }

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

// CHECK-DAG: OpEntryPoint GLCompute [[foo:%[a-zA-Z0-9_]+]] "foo"
// CHECK-DAG: OpEntryPoint GLCompute [[bar:%[a-zA-Z0-9_]+]] "bar"
// CHECK-NOT: OpVariable {{.*}} Workgroup
// CHECK: [[shared:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} Workgroup
// CHECK-NOT: OpVariable {{.*}} Workgroup
// CHECK: [[foo]] = OpFunction
// CHECK: OpAccessChain {{.*}} [[shared]]
// CHECK: [[bar]] = OpFunction
// CHECK: OpAccessChain {{.*}} [[shared]]

