// RUN: clspv --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that conversions from short8 to int8 is supported.

// CHECK-DAG: [[INT:%[0-9a-zA-Z_]+]] = OpTypeInt 32
//
// CHECK: OpSConvert [[INT]]
// CHECK: OpSConvert [[INT]]
// CHECK: OpSConvert [[INT]]
// CHECK: OpSConvert [[INT]]
// CHECK: OpSConvert [[INT]]
// CHECK: OpSConvert [[INT]]
// CHECK: OpSConvert [[INT]]
// CHECK: OpSConvert [[INT]]

void kernel test(global short *in, global int *out) {
  // Because long vectors are not supported as kernel argument, we rely on
  // vload8 and vstore8 to read/write the values.
  short8 x = vload8(0, in);
  int8 y = convert_int8(x);
  vstore8(y, 0, out);
}
