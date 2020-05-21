// RUN: clspv %s -verify -no-16bit-storage=ssbo -w

// Lack of ssbo support for 16-bit values shouldn't prohibit this kernel.
kernel void foo(short x) {} //expected-no-diagnostics
