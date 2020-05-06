// RUN: clspv -verify %s -no-8bit-storage=ssbo -w

kernel void foo(global char* a) { } //expected-error{{8-bit storage is not supported for SSBOs}}

kernel void bar(constant char* a) { } //expected-error{{8-bit storage is not supported for SSBOs}}

kernel void baz(uchar a) { } //expected-error{{8-bit storage is not supported for SSBOs}}

