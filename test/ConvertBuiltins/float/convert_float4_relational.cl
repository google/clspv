// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float4* output, int4 x) {
  output[0] = convert_float4(x > 0);
}

// CHECK: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[float4:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 4
// CHECK: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK: [[bool4:%[a-zA-Z0-9_]+]] = OpTypeVector [[bool]] 4
// CHECK: [[float_n1:%[a-zA-Z0-9_]+]] = OpConstant [[float]] -1
// CHECK: [[float4_true:%[a-zA-Z0-9_]+]] = OpConstantComposite [[float4]] [[float_n1]] [[float_n1]] [[float_n1]] [[float_n1]]
// CHECK: [[float4_false:%[a-zA-Z0-9_]+]] = OpConstantNull [[float4]]
// CHECK: [[greater:%[a-zA-Z0-9_]+]] = OpSGreaterThan [[bool4]]
// CHECK: [[select:%[a-zA-Z0-9_]+]] = OpSelect [[float4]] [[greater]] [[float4_true]] [[float4_false]]
