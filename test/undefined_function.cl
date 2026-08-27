// RUN: not clspv %target %s -o %t.spv 2>&1 | FileCheck %s
// CHECK: error: undefined reference to 'undefined_function'

int undefined_function(int a);

kernel void test_kernel(global int *out, int in) {
  *out = undefined_function(in);
}
