// RUN: clspv %target --long-vector %s -o %t.spv
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

void kernel test(global int8 *in, global float8 *out) {
  *out = convert_float8(*in);
}
