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

void kernel test(global int *in, global int *out) {
  // Because long vectors are not supported as kernel argument, we rely on
  // vload8 and vstore8 to read/write the values.
  int8 in0 = vload8(0, in);
  int8 in1 = vload8(1, in);
  int8 value = max(in0, in1);
  vstore8(value, 0, out);
}
