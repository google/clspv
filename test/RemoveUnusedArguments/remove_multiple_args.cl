// RUN: clspv %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

int bar(float x, int y, float z) { return y; }
void kernel foo(global int* x) { *x = bar(1.0f, *x, 1.0f); }

// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-NOT: OpFunctionParameter
// CHECK: OpFunctionParameter [[int]]
// CHECK-NOT: OpFunctionParameter
