// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[EXT:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[half:%[a-zA-Z0-9_]+]] = OpTypeFloat 16
// CHECK-DAG: [[half3:%[a-zA-Z0-9_]+]] = OpTypeVector [[half]] 3
// CHECK-DAG: [[ld0:%[a-zA-Z0-9_]+]] = OpLoad [[half3]]
// CHECK-DAG: [[ld1:%[a-zA-Z0-9_]+]] = OpLoad [[half3]]
// CHECK: OpExtInst [[half3]] [[EXT]] NMax [[ld0]] [[ld1]]

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

kernel void foo(global half3* in, global half3* out) {
  *out = fmax(in[0], in[1]);
}

