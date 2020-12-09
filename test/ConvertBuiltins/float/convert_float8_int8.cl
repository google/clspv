// RUN: clspv --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that conversions from int8 to float8 is supported.

// CHECK-DAG: [[INT:%[0-9a-zA-Z_]+]]   = OpTypeInt 32
// CHECK-DAG: [[FLOAT:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
//
// CHECK: OpConvertSToF [[FLOAT]]
// CHECK: OpConvertSToF [[FLOAT]]
// CHECK: OpConvertSToF [[FLOAT]]
// CHECK: OpConvertSToF [[FLOAT]]
// CHECK: OpConvertSToF [[FLOAT]]
// CHECK: OpConvertSToF [[FLOAT]]
// CHECK: OpConvertSToF [[FLOAT]]
// CHECK: OpConvertSToF [[FLOAT]]

void kernel test(global int *in, global float *out) {
  // Because long vectors are not supported as kernel argument, we rely on
  // vload8 and vstore8 to read/write the values.
  int8 x = vload8(0, in);
  float8 y = convert_float8(x);
  vstore8(y, 0, out);
}
