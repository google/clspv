// RUN: clspv -constant-args-ubo -verify -inline-entry-points %s

struct dt {
  int x;
  int4 y;
};

__kernel void foo(__constant struct dt* c) { } //expected-error{{clspv restriction: UBO structures may not have implicit padding}}
