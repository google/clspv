// RUN: clspv %s --long-vector -verify
//
// Test that long-vector types are rejected when used through kernel parameters.

typedef struct {
  float8 x;
} S;

kernel void test(global S *x) { // expected-error{{vectors with more than 4 elements are not supported as kernel parameters}}
  (void)x;
}
