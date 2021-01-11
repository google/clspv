// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

kernel void foo(global half4* output, int4 x) {
  output[0] = convert_half4(x > 0);
}

// CHECK: [[half:%[a-zA-Z0-9_]+]] = OpTypeFloat 16
// CHECK: [[half4:%[a-zA-Z0-9_]+]] = OpTypeVector [[half]] 4
// CHECK: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK: [[bool4:%[a-zA-Z0-9_]+]] = OpTypeVector [[bool]] 4
// CHECK: [[half_n1:%[a-zA-Z0-9_]+]] = OpConstant [[half]] -0x1p+0
// CHECK: [[half4_true:%[a-zA-Z0-9_]+]] = OpConstantComposite [[half4]] [[half_n1]] [[half_n1]] [[half_n1]] [[half_n1]]
// CHECK: [[half4_false:%[a-zA-Z0-9_]+]] = OpConstantNull [[half4]]
// CHECK: [[greater:%[a-zA-Z0-9_]+]] = OpSGreaterThan [[bool4]]
// CHECK: [[select:%[a-zA-Z0-9_]+]] = OpSelect [[half4]] [[greater]] [[half4_true]] [[half4_false]]
