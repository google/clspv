// RUN: clspv %s --long-vector -verify
//
// Test that long-vector types are supported as parameters of non-kernel functions.
//
// expected-no-diagnostics

typedef struct {
  float8 x;
} S;

void test(global S *x);
void test(global S *x) { (void)x; }
