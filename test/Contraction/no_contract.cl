// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// CHECK: OpDecorate [[mul:%[a-zA-Z0-9_]+]] NoContraction
// CHECK-NOT: OpExtInst %{{.*}} %{{.*}} Fma
// CHECK: [[mul]] = OpFMul
// CHECK: OpFAdd %{{.*}} [[mul]]

// RUN: clspv %target %s -o %t2.spv -cl-unsafe-math-optimizations
// RUN: spirv-dis %t2.spv -o %t2.spvasm
// RUN: FileCheck --check-prefix=FAST %s < %t2.spvasm
// FAST-NOT: OpDecorate [[mul:%[a-zA-Z0-9_]+]] NoContraction
// FAST-NOT: OpExtInst %{{.*}} %{{.*}} Fma
// FAST: [[mul:%[a-zA-Z0-9_]+]] = OpFMul
// FAST: OpFAdd %{{.*}} [[mul]]

// RUN: clspv %target %s -o %t2.spv -cl-mad-enable
// RUN: spirv-dis %t2.spv -o %t2.spvasm
// RUN: FileCheck --check-prefix=MAD %s < %t2.spvasm
// MAD-NOT: OpDecorate [[mul:%[a-zA-Z0-9_]+]] NoContraction
// MAD-NOT: OpExtInst %{{.*}} %{{.*}} Fma
// MAD: [[mul:%[a-zA-Z0-9_]+]] = OpFMul
// MAD: OpFAdd %{{.*}} [[mul]]

#pragma OPENCL FP_CONTRACT OFF
kernel void test(global float *out, global float *a, global float *b, global float *c) {
  int i = get_global_id(0);
  out[i] = a[i] * b[i] + c[i];
}

