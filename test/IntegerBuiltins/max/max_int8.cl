// RUN: clspv --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that max for int8 is supported.

// CHECK: [[GLSL:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
//
// CHECK: [[INT:%[0-9a-zA-Z_]+]] = OpTypeInt 32
//
// CHECK: OpExtInst [[INT]] [[GLSL]] SMax
// CHECK: OpExtInst [[INT]] [[GLSL]] SMax
// CHECK: OpExtInst [[INT]] [[GLSL]] SMax
// CHECK: OpExtInst [[INT]] [[GLSL]] SMax
// CHECK: OpExtInst [[INT]] [[GLSL]] SMax
// CHECK: OpExtInst [[INT]] [[GLSL]] SMax
// CHECK: OpExtInst [[INT]] [[GLSL]] SMax
// CHECK: OpExtInst [[INT]] [[GLSL]] SMax

void kernel test(global int8 *in, global int8 *out) {
  *out = max(in[0], in[1]);
}
