// RUN: clspv %target %s --long-vector -verify
//
// expected-no-diagnostics

kernel void test(float8 x) {
  (void)x;
}
