// RUN: clspv %s -o %t.spv -cluster-pod-kernel-args=0
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck --check-prefix=CHECK %s < %t.spvasm

// RUN: clspv %s -o %t2.spv -cluster-pod-kernel-args=1
// RUN: spirv-dis %t2.spv -o %t2.spvasm
// RUN: FileCheck --check-prefix=CHECK %s < %t2.spvasm

kernel void test(global int* in, int m, int n, global int* unused, global int* out) {
  out[n] = in[m];
}

// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[int_5:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 5
// CHECK-DAG: [[name:%[a-zA-Z0-9_]+]] = OpString "test"
// CHECK: Kernel {{%.*}} [[name]] [[int_5]]
