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

void kernel test(global ushort *in, global ushort *out) {
  // Because long vectors are not supported as kernel argument, we rely on
  // vload8 and vstore8 to read/write the values.
  ushort8 in0 = vload8(0, in);
  ushort8 in1 = vload8(1, in);
  ushort8 value = max(in0, in1);
  vstore8(value, 0, out);
}
