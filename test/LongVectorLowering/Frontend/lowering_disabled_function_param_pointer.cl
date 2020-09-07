// RUN: clspv %s -verify
//
// Test that long-vector types are rejected when the support is not enabled.

void test(float8 *x);
void test(float8 *x) { (void)x; } // expected-error{{vectors with more than 4 elements are not supported}}
