// RUN: clspv %s --long-vector -verify

// Ensure all builtins are declared (i.e. there are no warnings about implicit
// declaration).
//
// expected-no-diagnostics

// TODO Check that the appropriate SPIR-V instructions are generated once max is
// supported.

kernel void test(global int *in, global int *out) {
  {
    int8 a = vload8(0, in);
    int8 b = vload8(1, in);
    int8 c = max(a, b);
    vstore8(c, 0, out);
  }

  {
    int4 a = vload4(0, in);
    int4 b = vload4(1, in);
    int4 c = max(a, b);
    vstore4(c, 2, out);
  }
}
