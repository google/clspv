// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global double* output, int x) {
  bool r = (x > 0);
  output[0] = (double)(r);
}

// CHECK: [[double:%[a-zA-Z0-9_]+]] = OpTypeFloat 64
// CHECK: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK: [[double_1:%[a-zA-Z0-9_]+]] = OpConstant [[double]] 1
// CHECK: [[double_0:%[a-zA-Z0-9_]+]] = OpConstant [[double]] 0
// CHECK: [[greater:%[a-zA-Z0-9_]+]] = OpSGreaterThan [[bool]]
// CHECK: [[select:%[a-zA-Z0-9_]+]] = OpSelect [[double]] [[greater]] [[double_1]] [[double_0]]
