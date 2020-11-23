// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

#pragma OPENCL EXTENSION cl_khr_fp16: enable

kernel void foo(global half* output, int x) {
  bool r = (x > 0);
  output[0] = (half)(r);
}

// CHECK: [[half:%[a-zA-Z0-9_]+]] = OpTypeFloat 16
// CHECK: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK: [[half_1:%[a-zA-Z0-9_]+]] = OpConstant [[half]] 0x1p+0
// CHECK: [[half_0:%[a-zA-Z0-9_]+]] = OpConstant [[half]] 0x0p+0
// CHECK: [[greater:%[a-zA-Z0-9_]+]] = OpSGreaterThan [[bool]]
// CHECK: [[select:%[a-zA-Z0-9_]+]] = OpSelect [[half]] [[greater]] [[half_1]] [[half_0]]
