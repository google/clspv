// RUN: not clspv -arch=spirv64 -physical-storage-buffers %s -o %t.spv 2>&1 | FileCheck %s
// CHECK: error: undefined reference to 'undefined_function'

void undefined_function(global int *a);

kernel void test_kernel(global int *out) {
  undefined_function(out);
}
