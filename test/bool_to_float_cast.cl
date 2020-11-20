// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float* output, int x) {
  bool r = (x > 0);
  output[0] = (float)(r);
}

// CHECK: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK: [[float_1:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 1
// CHECK: [[float_0:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 0
// CHECK: [[greater:%[a-zA-Z0-9_]+]] = OpSGreaterThan [[bool]]
// CHECK: [[select:%[a-zA-Z0-9_]+]] = OpSelect [[float]] [[greater]] [[float_1]] [[float_0]]
