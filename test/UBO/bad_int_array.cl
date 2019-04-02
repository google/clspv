// RUN: clspv %s -w -constant-args-ubo -verify -inline-entry-points

kernel void foo(__constant int* c) { } //expected-error{{clspv restriction: to satisfy UBO ArrayStride restrictions, element size must be a multiple of array alignment}}
