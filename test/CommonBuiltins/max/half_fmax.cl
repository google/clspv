// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[EXT:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[half:%[a-zA-Z0-9_]+]] = OpTypeFloat 16
// CHECK-DAG: [[half2:%[a-zA-Z0-9_]+]] = OpTypeVector [[half]] 2
// CHECK-DAG: [[ld0:%[a-zA-Z0-9_]+]] = OpLoad [[half2]]
// CHECK-DAG: [[ld1:%[a-zA-Z0-9_]+]] = OpLoad [[half2]]
// CHECK: OpExtInst [[half2]] [[EXT]] FMax [[ld0]] [[ld1]]

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

kernel void foo(global half2* in, global half2* out) {
  *out = fmax(in[0], in[1]);
}

