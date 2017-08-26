// Test for https://github.com/google/clspv/issues/15
// Use of <4 x 18> was generating a duplicate of OpTypeInt 32 0.

// In this example, the char4 is mentioned before the uint.
kernel void dup(global char4* A, global uint *B) {}

// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// CHECK: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
// CHECK-NOT: OpTypeInt 32 0

// Ensure both buffer types use the same underlying i32
// CHECK-DAG: OpTypeRuntimeArray [[uint]]
// CHECK-DAG: OpTypeRuntimeArray [[uint]]

