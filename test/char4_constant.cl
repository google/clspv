
// Test for https://github.com/google/clspv/issues/36
// A <4 x 18> constant was generated incorrectly.

kernel void dup(global uchar4 *B) {
   *B = (uchar4)(1,128,3,4);
}

// RUN: clspv %target %s -o %t.spv -int8=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// CHECK-DAG: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
// CHECK-DAG: [[theconst:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 25166596
// CHECK-DAG: OpStore {{%[_a-zA-Z0-9]+}} [[theconst]]
// CHECK-NOT: OpStore
