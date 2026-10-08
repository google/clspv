// Merging these two constant GEPs yields 800 bits over a 128-bit element
// (84-byte struct field + 16-byte array member). Truncating that to 6 moves
// the access into the middle of the wrong array.

// RUN: clspv %target %s -O2 -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv

// opad.w1[idx] and ipad.h[idx] keep the correct member path.
// CHECK: OpAccessChain %_ptr_Function_uint {{%[0-9]+}} %uint_1 %uint_1 %{{[0-9]+}}
// CHECK: OpAccessChain %_ptr_Function_uint {{%[0-9]+}} %uint_0 %uint_0 %{{[0-9]+}}

typedef struct inner_t {
  int h[4];
  int w0[4];
  int w1[4];
  int w2[4];
  int w3[4];
  int len;
} inner_t;

typedef struct outer_t {
  inner_t ipad;
  inner_t opad;
} outer_t;

kernel void repro(global int* out, int seed) {
  outer_t c;
  c.opad.w0[0] = seed;
  c.opad.w0[1] = seed + 1;
  c.opad.w0[2] = seed + 2;
  c.opad.w0[3] = seed + 3;
  c.opad.len = seed + 4;
  int (*p)[4] = &c.opad.w0;
  int i = seed & 3;
  (*p)[i] = (*p)[i] + 1;
  out[0] = (*p)[0] + c.opad.len;
  out[1] = c.ipad.h[seed & 3];
}
