// RUN: clspv -w -constant-args-ubo -verify -inline-entry-points %s

struct dt {
  int x[2]; //expected-note{{here}}
  int y;
} __attribute((aligned(16)));

__kernel void foo(__constant struct dt* c) { } //expected-error{{clspv restriction: to satisfy UBO ArrayStride restrictions, element size must be a multiple of array alignment}}
