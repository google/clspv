// RUN: clspv %target --long-vector %s -o %t.spv --use-native-builtins=convert_short8
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

void kernel test(global int8 *in, global short8 *out) {
  *out = convert_short8(*in);
}
