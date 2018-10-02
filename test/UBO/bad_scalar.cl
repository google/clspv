// RUN: clspv %s -constant-args-ubo -verify -inline-entry-points

struct s {
  uchar x;
  int y;
} __attribute((packed));

__kernel void foo(__constant struct s* arg) { } //expected-error{{in an UBO, scalar elements must be aligned to their size}}
