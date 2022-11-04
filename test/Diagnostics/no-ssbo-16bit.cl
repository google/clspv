// RUN: clspv %target -verify %s -no-16bit-storage=ssbo -w

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

struct A {
  half4 x;
};

struct B {
  struct A a[2];
};

kernel void foo(global short* a) { } //expected-error{{16-bit storage is not supported for SSBOs}}

kernel void bar(constant struct B* a) { } //expected-error{{16-bit storage is not supported for SSBOs}}
