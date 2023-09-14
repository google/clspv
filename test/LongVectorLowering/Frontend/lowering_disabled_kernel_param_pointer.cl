// RUN: clspv %target %s -verify
// TODO(#1231)
// XFAIL: *
//
// Test that long-vector types are rejected when the support is not enabled.

kernel void test(global float8* x) { // expected-error{{vectors with more than 4 elements are not supported}}
  (void)x;
}
