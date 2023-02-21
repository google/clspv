// RUN: clspv %target --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that conversions from float16 to char16 is supported.

// CHECK-DAG: [[CHAR:%[0-9a-zA-Z_]+]]  = OpTypeInt 8
// CHECK-DAG: [[FLOAT:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[CHAR_VEC:%[0-9a-zA-Z_]+]] = OpTypeVector [[CHAR]] 2
//
// CHECK: OpConvertFToS [[CHAR_VEC]]
// CHECK: OpConvertFToS [[CHAR_VEC]]
// CHECK: OpConvertFToS [[CHAR_VEC]]
// CHECK: OpConvertFToS [[CHAR_VEC]]
// CHECK: OpConvertFToS [[CHAR_VEC]]
// CHECK: OpConvertFToS [[CHAR_VEC]]
// CHECK: OpConvertFToS [[CHAR_VEC]]
// CHECK: OpConvertFToS [[CHAR_VEC]]

void kernel test(global float16 *in, global char16 *out) {
  *out = convert_char16(*in);
}
