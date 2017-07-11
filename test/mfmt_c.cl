// RUN: clspv %s -mfmt=c -o %t.inc
// RUN: FileCheck %s < %t.inc

// The first three words in the header.
// CHECK: {0x7230203, 0x10000, 0x30000,
// The OpFunctionEnd at the very end.
// CHECK: 0x10038}

kernel void foo(global uint *a) {}
