// RUN: clspv %target %s -Werror -verify

kernel void foo(int arg) { } //expected-error{{unused parameter}}
