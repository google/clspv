// RUN: clspv --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that conversions from int8 to short8 is supported.

// CHECK-DAG: [[SHORT:%[0-9a-zA-Z_]+]]  = OpTypeInt 16
//
// CHECK: OpUConvert [[SHORT]]
// CHECK: OpUConvert [[SHORT]]
// CHECK: OpUConvert [[SHORT]]
// CHECK: OpUConvert [[SHORT]]
// CHECK: OpUConvert [[SHORT]]
// CHECK: OpUConvert [[SHORT]]
// CHECK: OpUConvert [[SHORT]]
// CHECK: OpUConvert [[SHORT]]

void kernel test(global int *in, global short *out) {
  // Because long vectors are not supported as kernel argument, we rely on
  // vload8 and vstore8 to read/write the values.
  int8 x = vload8(0, in);
  short8 y = convert_short8(x);
  vstore8(y, 0, out);
}
