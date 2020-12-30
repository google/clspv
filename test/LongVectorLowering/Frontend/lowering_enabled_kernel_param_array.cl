// RUN: clspv %s --long-vector -verify
//
// expected-no-diagnostics

kernel void test(global float8 x[10]) {
  (void)x;
}
