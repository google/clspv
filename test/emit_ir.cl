// RUN: clspv %s --emit-ir=%t.ll
// RUN: FileCheck %s < %t.ll

void kernel foo(global double *out, int in)
{
  *out = in / 2.304;
}

// CHECK: target triple = "spir-unknown-unknown"
// CHECK: define
// CHECK-SAME: spir_kernel
// CHECK-SAME: void @foo(double addrspace(1)* noundef %out, i32 noundef %in)
