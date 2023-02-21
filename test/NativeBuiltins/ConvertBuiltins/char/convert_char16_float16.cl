// RUN: clspv %target --long-vector %s -o %t.spv --use-native-builtins=convert_char16
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that conversions from float16 to char16 is supported.

// CHECK-DAG: [[CHAR:%[0-9a-zA-Z_]+]]  = OpTypeInt 8
// CHECK-DAG: [[FLOAT:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
//
// CHECK: OpConvertFToS [[CHAR]]
// CHECK: OpConvertFToS [[CHAR]]
// CHECK: OpConvertFToS [[CHAR]]
// CHECK: OpConvertFToS [[CHAR]]
// CHECK: OpConvertFToS [[CHAR]]
// CHECK: OpConvertFToS [[CHAR]]
// CHECK: OpConvertFToS [[CHAR]]
// CHECK: OpConvertFToS [[CHAR]]
// CHECK: OpConvertFToS [[CHAR]]
// CHECK: OpConvertFToS [[CHAR]]
// CHECK: OpConvertFToS [[CHAR]]
// CHECK: OpConvertFToS [[CHAR]]
// CHECK: OpConvertFToS [[CHAR]]
// CHECK: OpConvertFToS [[CHAR]]
// CHECK: OpConvertFToS [[CHAR]]
// CHECK: OpConvertFToS [[CHAR]]

void kernel test(global float16 *in, global char16 *out) {
  *out = convert_char16(*in);
}
