// RUN: clspv --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that conversions from short8 to half8 is supported.

// CHECK-DAG: [[SHORT:%[0-9a-zA-Z_]+]] = OpTypeInt 16
// CHECK-DAG: [[HALF:%[0-9a-zA-Z_]+]]  = OpTypeFloat 16
//
// CHECK: OpConvertSToF [[HALF]]
// CHECK: OpConvertSToF [[HALF]]
// CHECK: OpConvertSToF [[HALF]]
// CHECK: OpConvertSToF [[HALF]]
// CHECK: OpConvertSToF [[HALF]]
// CHECK: OpConvertSToF [[HALF]]
// CHECK: OpConvertSToF [[HALF]]
// CHECK: OpConvertSToF [[HALF]]

void kernel test(global short *in, global half *out) {
  // Because long vectors are not supported as kernel argument, we rely on
  // vload8 and vstore8 to read/write the values.
  short8 x = vload8(0, in);
  half8 y = convert_half8(x);
  vstore8(y, 0, out);
}
