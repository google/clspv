// RUN: clspv %target %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

int bar(global int* x) { return *x; }
void kernel foo(global int* x, global int* y) { *x = bar(y); }

// CHECK-NOT: OpFunctionParameter

