// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// CHECK: OpExtInst %{{.*}} %{{.*}} Fma

#pragma OPENCL FP_CONTRACT ON
kernel void test(global float *out, global float *a, global float *b, global float *c) {
  int i = get_global_id(0);
  out[i] = a[i] * b[i] + c[i];
}
