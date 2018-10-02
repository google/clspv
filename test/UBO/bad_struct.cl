// RUN: clspv -constant-args-ubo -verify -inline-entry-points %s

struct inner {
  int x;
};

struct outer {
  int x;
  struct inner y;
};

__kernel void foo(__constant struct outer* c) { } //expected-error{{in an UBO, structs must be aligned to their largest element alignment, rounded up to a multiple of 16 bytes}}
