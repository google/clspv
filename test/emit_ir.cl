// RUN: clspv %s --emit-ir=%t.ll
// RUN: FileCheck %s < %t.ll

// RUN: clspv %s --emit-ir=%t.bc --emit-binary-ir
// RUN: llvm-dis %t.bc -o %t.bc.ll
// RUN: FileCheck %s < %t.bc.ll

// RUN: clspv %s --emit-binary-ir -o %t.2.bc
// RUN: llvm-dis %t.2.bc -o %t.2.bc.ll
// RUN: FileCheck %s < %t.2.bc.ll

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
