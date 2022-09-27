// RUN: clspv %target -verify %s -no-8bit-storage=pushconstant -w -pod-pushconstant

kernel void bar(char a) { } //expected-error{{8-bit storage is not supported for push constants}}

kernel void baz(uchar a) { } //expected-error{{8-bit storage is not supported for push constants}}

