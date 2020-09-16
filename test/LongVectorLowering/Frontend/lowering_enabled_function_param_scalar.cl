// RUN: clspv %s --long-vector -verify
//
// Test that long-vector types are supported as parameters of non-kernel functions.
//
// expected-no-diagnostics

void test(float8 x);
void test(float8 x) { (void)x; }
