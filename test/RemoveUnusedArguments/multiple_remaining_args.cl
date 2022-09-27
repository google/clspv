// RUN: clspv %target %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__attribute__((noinline))
int bar(float a, int b, float c, int d) { return b + d; }
void kernel foo(global int* x, global float* y) { x[0] = bar(1.0f, x[1], 1.0f, x[2]); }

// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-NOT: OpFunctionParameter [[float]]
// CHECK: OpFunctionParameter [[int]]
// CHECK-NEXT: OpFunctionParameter [[int]]
// CHECK-NOT: OpFunctionParameter [[float]]

