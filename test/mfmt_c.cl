// RUN: clspv %s --output-format=c -o %t.inc
// RUN: FileCheck %s < %t.inc

// The first three words in the header.
// CHECK: {119734787,
// CHECK-NEXT: 65536,
// CHECK-NEXT: 1376256,
// The OpReturn and OpFunctionEnd towards the end.
// CHECK: 65789,
// CHECK-NEXT: 65592,

kernel void foo(global uint *a) {}
