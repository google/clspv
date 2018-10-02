// RUN: clspv %s -constant-args-ubo -verify -inline-entry-points

struct s {
  uchar x;
  int2 y;
} __attribute((packed));

__kernel void foo(__constant struct s* arg) { } //expected-error{{in an UBO, two-component vectors must be aligned to 2 times their element size}}
