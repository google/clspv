// RUN: clspv %s -constant-args-ubo -verify -inline-entry-points

struct s {
  uchar x;
  int2 y; //expected-note{{here}}
} __attribute((packed)) __attribute((aligned(16)));

__kernel void foo(__global struct s* arg) { } //expected-error{{two-component vectors must be aligned to 2 times their element size}}
