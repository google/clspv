// RUN: clspv %s --long-vector -verify
//
// Test that long-vector types are rejected when used through kernel parameters.

kernel void test(global float8* x) { // expected-error{{vectors with more than 4 elements are not supported as kernel parameters}}
  (void)x;
}
