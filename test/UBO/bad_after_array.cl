// RUN: clspv -constant-args-ubo -verify -inline-entry-points %s

struct dt {
  int x[2];
  int y;
};

__kernel void foo(__constant struct dt* c) { } //expected-error{{clspv restriction: UBO element size must be a multiple of that element's alignment}}
