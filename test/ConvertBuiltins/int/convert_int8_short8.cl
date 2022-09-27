// RUN: clspv %target --long-vector %s -o %t.spv
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

void kernel test(global short8 *in, global int8 *out) {
  *out = convert_int8(*in);
}
