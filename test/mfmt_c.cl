// RUN: clspv %s -mfmt=c -o %t.inc
// RUN: FileCheck %s < %t.inc

// The first three words in the header.
// CHECK: {119734787,
// CHECK-NEXT: 65536,
// CHECK-NEXT: 196608,
// The OpReturn and OpFunctionEnd at the very end.
// CHECK: 65789,
// CHECK-NEXT: 65592}

kernel void foo(global uint *a) {}
