// Test for https://github.com/google/clspv/issues/166
// Function declarations were missing from builtin header.

// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(global float *A, uint a) {
  *A = as_float(a);
}

// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[int]]
// CHECK: OpBitcast [[float]] [[ld]]
