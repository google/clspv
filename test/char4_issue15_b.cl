// Test for https://github.com/google/clspv/issues/15
// Use of <4 x 18> was generating a duplicate of OpTypeInt 32 0.

// In this example, the char4 is mentioned before the uint.
kernel void dup(global char4* A, global uint *B) {
  *A = (char4)(0,0,0,0);
  *B = 0;
}

// RUN: clspv %target %s -o %t.spv -int8=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// CHECK-DAG: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
// CHECK-NOT: OpTypeInt 32 0

// Ensure both buffer types use the same underlying i32
// CHECK-DAG: OpTypeRuntimeArray [[uint]]
// CHECK-DAG: OpTypeRuntimeArray [[uint]]

