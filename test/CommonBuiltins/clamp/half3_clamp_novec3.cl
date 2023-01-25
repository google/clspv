// RUN: clspv %target %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[EXT:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[half:%[a-zA-Z0-9_]+]] = OpTypeFloat 16
// CHECK-DAG: [[half4:%[a-zA-Z0-9_]+]] = OpTypeVector [[half]] 4
// CHECK-DAG: [[ld0:%[a-zA-Z0-9_]+]] = OpLoad [[half4]]
// CHECK-DAG: [[ld1:%[a-zA-Z0-9_]+]] = OpLoad [[half4]]
// CHECK-DAG: [[ld2:%[a-zA-Z0-9_]+]] = OpLoad [[half4]]
// CHECK: OpExtInst [[half4]] [[EXT]] NClamp [[ld0]] [[ld1]] [[ld2]]

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

kernel void foo(global half3* in, global half3* out) {
  *out = clamp(in[0], in[1], in[2]);
}


