// RUN: clspv %target %s --long-vector -verify
//
// Test that long-vector types are supported as parameters of non-kernel functions.
//
// expected-no-diagnostics

void test(global float8 x[10]);
void test(global float8 x[10]) { (void)x; }
