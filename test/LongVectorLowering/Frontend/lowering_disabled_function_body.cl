// RUN: clspv %target %s -verify
//
// Test that long-vector types are rejected when the support is not enabled.

kernel void test(global int* data) {
  float8 x; // expected-error{{vectors with more than 4 elements are not supported}}
  (void)x;
  *data = 0;
}
