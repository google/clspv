// RUN: clspv --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that exp for float8 is supported.

// CHECK: [[GLSL:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
//
// CHECK: [[FLOAT:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
//
// CHECK: OpExtInst [[FLOAT]] [[GLSL]] Exp
// CHECK: OpExtInst [[FLOAT]] [[GLSL]] Exp
// CHECK: OpExtInst [[FLOAT]] [[GLSL]] Exp
// CHECK: OpExtInst [[FLOAT]] [[GLSL]] Exp
// CHECK: OpExtInst [[FLOAT]] [[GLSL]] Exp
// CHECK: OpExtInst [[FLOAT]] [[GLSL]] Exp
// CHECK: OpExtInst [[FLOAT]] [[GLSL]] Exp
// CHECK: OpExtInst [[FLOAT]] [[GLSL]] Exp

void kernel test(global float *in, global float *out) {
  // Because long vectors are not supported as kernel argument, we rely on
  // vload8 and vstore8 to read/write the values.
  float8 x = vload8(0, in);
  float8 y = exp(x);
  vstore8(y, 0, out);
}
