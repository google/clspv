// RUN: clspv %target %s -w -verify

kernel void foo(int arg) { } //expected-no-diagnostics
