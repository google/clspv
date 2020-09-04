// RUN: clspv --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that fma for float8 is supported.

// CHECK: [[GLSL:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
//
// CHECK: [[FLOAT:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
//
// CHECK: OpExtInst [[FLOAT]] [[GLSL]] Fma
// CHECK: OpExtInst [[FLOAT]] [[GLSL]] Fma
// CHECK: OpExtInst [[FLOAT]] [[GLSL]] Fma
// CHECK: OpExtInst [[FLOAT]] [[GLSL]] Fma
// CHECK: OpExtInst [[FLOAT]] [[GLSL]] Fma
// CHECK: OpExtInst [[FLOAT]] [[GLSL]] Fma
// CHECK: OpExtInst [[FLOAT]] [[GLSL]] Fma
// CHECK: OpExtInst [[FLOAT]] [[GLSL]] Fma

void kernel test(global float *in, global float *out) {
  // Because long vectors are not supported as kernel argument, we rely on
  // vload8 and vstore8 to read/write the values.
  float8 in0 = vload8(0, in);
  float8 in1 = vload8(1, in);
  float8 in2 = vload8(2, in);
  float8 value = fma(in0, in1, in2);
  vstore8(value, 0, out);
}
