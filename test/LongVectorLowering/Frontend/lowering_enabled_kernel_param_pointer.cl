// RUN: clspv %target %s --long-vector -verify
//
// expected-no-diagnostics

kernel void test(global float8* x) {
  (void)x;
}
