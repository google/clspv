// RUN: clspv %target %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

int bar(int x) { return 0; }
void kernel foo(global int* x) { *x = bar(1); }

// CHECK-NOT: OpFunctionParameter
