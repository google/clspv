// RUN: clspv %target -verify %s -no-16bit-storage=ubo -w -pod-ubo -constant-args-ubo -std430-ubo-layout

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

kernel void foo(constant half* a) { } //expected-error{{16-bit storage is not supported for UBOs}}

kernel void bar(ushort a) { } //expected-error{{16-bit storage is not supported for UBOs}}

kernel void baz(short a) { } //expected-error{{16-bit storage is not supported for UBOs}}

