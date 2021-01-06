// RUN: clspv --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that max for ushort8 is supported.

// CHECK: [[GLSL:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
//
// CHECK: [[USHORT:%[0-9a-zA-Z_]+]] = OpTypeInt 16
//
// CHECK: OpExtInst [[USHORT]] [[GLSL]] UMax
// CHECK: OpExtInst [[USHORT]] [[GLSL]] UMax
// CHECK: OpExtInst [[USHORT]] [[GLSL]] UMax
// CHECK: OpExtInst [[USHORT]] [[GLSL]] UMax
// CHECK: OpExtInst [[USHORT]] [[GLSL]] UMax
// CHECK: OpExtInst [[USHORT]] [[GLSL]] UMax
// CHECK: OpExtInst [[USHORT]] [[GLSL]] UMax
// CHECK: OpExtInst [[USHORT]] [[GLSL]] UMax

void kernel test(global ushort8 *in, global ushort8 *out) {
  *out = max(in[0], in[1]);
}
