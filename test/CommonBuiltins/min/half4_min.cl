// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[EXT:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[half:%[a-zA-Z0-9_]+]] = OpTypeFloat 16
// CHECK-DAG: [[half4:%[a-zA-Z0-9_]+]] = OpTypeVector [[half]] 4
// CHECK-DAG: [[ld0:%[a-zA-Z0-9_]+]] = OpLoad [[half4]]
// CHECK-DAG: [[ld1:%[a-zA-Z0-9_]+]] = OpLoad [[half4]]
// CHECK: OpExtInst [[half4]] [[EXT]] FMin [[ld0]] [[ld1]]

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

kernel void foo(global half4* in, global half4* out) {
  *out = min(in[0], in[1]);
}

