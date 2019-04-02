
// Test for https://github.com/google/clspv/issues/36
// A <4 x 18> constant was generated incorrectly.

kernel void dup(global uchar4 *B) {
   *B = (uchar4)(0,0,0,0);
}

// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// CHECK-DAG: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
// CHECK-DAG: [[theconst:%[_a-zA-Z0-9]+]] = OpConstantNull [[uint]]
// CHECK-DAG: OpStore {{%[_a-zA-Z0-9]+}} [[theconst]]
// CHECK-NOT: OpStore
