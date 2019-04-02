// RUN: clspv %s -verify

kernel void foo(int arg) { } //expected-warning{{unused parameter}}
