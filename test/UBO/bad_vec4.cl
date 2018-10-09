// RUN: clspv %s -constant-args-ubo -verify -inline-entry-points

struct s {
  uchar x;
  int4 y;
} __attribute((packed));

__kernel void foo(__constant struct s* arg) { } //expected-error{{in an UBO, three- and four-component vectors must be aligned to 4 times their element size}}

