// RUN: clspv  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int* a, global char3* b) {
  *a = all(*b);
}

// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK-DAG: [[char3:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 3
// CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[bool3:%[a-zA-Z0-9_]+]] = OpTypeVector [[bool]] 3
// CHECK-DAG: [[int_0:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK-DAG: [[int_1:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 1
// CHECK-DAG: [[null:%[a-zA-Z0-9_]+]] = OpConstantNull [[char3]]
// CHECK:     [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[char3]]
// CHECK:     [[less:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool3]] [[ld]] [[null]]
// CHECK:     [[all:%[a-zA-Z0-9_]+]] = OpAll [[bool]] [[less]]
// CHECK:     OpSelect [[int]] [[all]] [[int_1]] [[int_0]]

