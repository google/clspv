// RUN: clspv %target --long-vector %s -o %t.spv
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

void kernel test(global short8 *in, global half8 *out) {
  *out = convert_half8(*in);
}
