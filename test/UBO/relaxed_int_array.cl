// RUN: clspv %s -w -constant-args-ubo -verify -inline-entry-points -relaxed-ubo-layout

// With -relaxed-ubo-layout specified, the ArrayStride restriction is not checked.
// expected-no-diagnostics
kernel void foo(__constant int* c) { }

