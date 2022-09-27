// RUN: clspv %target -verify %s -no-8bit-storage=ubo -w -pod-ubo -constant-args-ubo -std430-ubo-layout

kernel void foo(constant char* a) { } //expected-error{{8-bit storage is not supported for UBOs}}

kernel void bar(uchar a) { } //expected-error{{8-bit storage is not supported for UBOs}}

kernel void baz(char a) { } //expected-error{{8-bit storage is not supported for UBOs}}

