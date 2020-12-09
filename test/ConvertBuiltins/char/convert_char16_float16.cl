// RUN: clspv --long-vector %s -o %t.spv
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

void kernel test(global float *in, global char *out) {
  // Because long vectors are not supported as kernel argument, we rely on
  // vload16 and vstore16 to read/write the values.
  float16 x = vload16(0, in);
  char16 y = convert_char16(x);
  vstore16(y, 0, out);
}
