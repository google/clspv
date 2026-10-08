// Regression test for SimplifyPointerBitcastPass: the merged GEP offset is
// not a whole number of the smaller element width (inner_t is 84 bytes =
// 672 bits, its w0 member is a [4 x i32] = 128 bits; 672 + 128 = 800,
// which is not divisible by 128). The pass used to truncate 800/128 to 6
// and rebuild a GEP pointing into the middle of opad.h, which the type walk
// rejected with "Err: SrcTy ... CstVal = 96" and an abort. The pass must
// leave the chain alone instead.

// RUN: clspv %target %s -O2 -o %t.spv
// RUN: spirv-val %t.spv

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
