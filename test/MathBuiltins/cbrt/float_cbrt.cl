// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-NOT: OpCapability Int16

__kernel void test_cbrt(__global float *out, __global float *in) {
  int gid = get_global_id(0);
  out[gid] = cbrt(in[gid]);
}
