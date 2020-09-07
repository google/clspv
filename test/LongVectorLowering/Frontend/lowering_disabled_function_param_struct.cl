// RUN: clspv %s -verify
//
// Test that long-vector types are rejected when the support is not enabled.

typedef struct {
  float8 x;
} S;

void test(global S *x);
void test(global S *x) { (void)x; } // expected-error{{vectors with more than 4 elements are not supported}}
