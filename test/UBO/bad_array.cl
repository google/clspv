// RUN: clspv %s -constant-args-ubo -verify -inline-entry-points

struct dt {
  int x;
  int y[4];
};

__kernel void foo(__constant struct dt* c) { } //expected-error{{in an UBO, arrays must be aligned to their element alignment, rounded up to a multiple of 16}}

