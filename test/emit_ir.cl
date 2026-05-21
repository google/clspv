// RUN: clspv %target %s --output-format=ll -o %t.ll
// RUN: FileCheck %s < %t.ll

// RUN: clspv %s --output-format=bc -o %t.bc
// RUN: llvm-dis %t.bc -o %t.bc.ll
// RUN: FileCheck %s < %t.bc.ll

void kernel foo(global double *out, int in)
{
  *out = in / 2.304;
}

// CHECK: target triple = "spirv{{(64|32)}}-unknown-vulkan"
// CHECK: define
// CHECK-SAME: spir_kernel
// CHECK-SAME: void @foo
// CHECK-SAME: ptr addrspace(1){{[^%]+}}%out
// CHECK-SAME: i32{{[^%]+}}%in
