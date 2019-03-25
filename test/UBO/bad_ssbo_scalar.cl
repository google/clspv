// RUN: clspv %s -constant-args-ubo -verify -inline-entry-points

struct s {
  uchar x;
  int y; //expected-note{{here}}
} __attribute((packed)) __attribute((aligned(16)));

__kernel void foo(__global struct s* arg) { } //expected-error{{scalar elements must be aligned to their size}}
