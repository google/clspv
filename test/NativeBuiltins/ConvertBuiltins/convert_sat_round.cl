// RUN: clspv %target -int8 --long-vector --cl-native-math %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv
// RUN: clspv %target -int8 --long-vector --use-native-builtins=convert_uchar8_sat_rte,convert_char4_sat %s -o %t2.spv
// RUN: spirv-dis %t2.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t2.spv

// Verify that saturated and explicit rounding-mode conversions preserve their
// saturation and rounding logic under --cl-native-math and --use-native-builtins,
// and that internal __clc_convert_u* helpers use unsigned FP-to-int conversion.

// CHECK-DAG: [[UCHAR:%[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: [[UINT:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[V4UINT:%[0-9a-zA-Z_]+]] = OpTypeVector [[UINT]] 4
// CHECK-DAG: [[FLOAT:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[V4FLOAT:%[0-9a-zA-Z_]+]] = OpTypeVector [[FLOAT]] 4
// CHECK-DAG: OpExtInst [[V4FLOAT]] {{%[0-9a-zA-Z_]+}} RoundEven
// CHECK-DAG: OpConvertFToU [[UCHAR]]
// CHECK-DAG: OpExtInst [[V4UINT]] {{%[0-9a-zA-Z_]+}} {{SClamp|SMin}}

void kernel test(global float8 *in_f8, global uchar8 *out_u8,
                 global int4 *in_i4, global char4 *out_c4) {
  *out_u8 = convert_uchar8_sat_rte(*in_f8);
  *out_c4 = convert_char4_sat(*in_i4);
}
