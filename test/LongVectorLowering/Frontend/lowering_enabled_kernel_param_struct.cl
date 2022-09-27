// RUN: clspv %target %s --long-vector -verify
//
// expected-no-diagnostics

typedef struct {
  float8 x;
} S;

kernel void test(global S *x) {
  (void)x;
}
