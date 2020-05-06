// RUN: clspv -verify %s -no-16bit-storage=pushconstant -w -pod-pushconstant

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

kernel void foo(short a) { } //expected-error{{16-bit storage is not supported for push constants}}

kernel void bar(half a) { } //expected-error{{16-bit storage is not supported for push constants}}

kernel void baz(ushort a) { } //expected-error{{16-bit storage is not supported for push constants}}
