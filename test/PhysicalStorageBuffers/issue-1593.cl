// RUN: clspv %s -o %t.spv --arch=spir64 --physical-storage-buffers
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

__kernel void foo(__global int* x, __global int* y) {
  int gid = (int) get_global_id(0);
  x[gid] = gid;
}
