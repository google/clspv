// RUN: clspv %s --output-format=ll -o %t.ll
// RUN: FileCheck %s < %t.ll

// RUN: clspv %s --output-format=bc -o %t.bc
// RUN: llvm-dis %t.bc -o %t.bc.ll
// RUN: FileCheck %s < %t.bc.ll

void kernel foo(global double *out, int in)
{
  *out = in / 2.304;
}

// CHECK: target triple = "spir-unknown-unknown"
// CHECK: define
// CHECK-SAME: spir_kernel
// CHECK-SAME: void @foo
// CHECK-SAME: double addrspace(1)*{{[^%]+}}%out
// CHECK-SAME: i32{{[^%]+}}%in
