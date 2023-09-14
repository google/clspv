// RUN: clspv %target %s -verify
// TODO(#1231)
// XFAIL: *
//
// Test that long-vector types are rejected when the support is not enabled.

void test(global float8 x[10]);
void test(global float8 x[10]) { (void)x; } // expected-error{{vectors with more than 4 elements are not supported}}
