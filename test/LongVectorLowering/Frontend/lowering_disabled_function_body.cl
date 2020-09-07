// RUN: clspv %s -verify
//
// Test that long-vector types are rejected when the support is not enabled.

kernel void test() {
  float8 x; // expected-error{{vectors with more than 4 elements are not supported}}
  (void)x;
}
