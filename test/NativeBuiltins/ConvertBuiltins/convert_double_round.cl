// RUN: clspv %target --cl-native-math %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv
// RUN: clspv %target --use-native-builtins=convert_double,convert_double4_rte,convert_double4_rtz %s -o %t2.spv
// RUN: spirv-dis %t2.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t2.spv

// Verify that default convert_double lowers natively while explicit rounding
// modes preserve their libclc rounding logic under --cl-native-math and
// --use-native-builtins.

// CHECK-DAG: [[I64:%[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: [[V4I64:%[0-9a-zA-Z_]+]] = OpTypeVector [[I64]] 4
// CHECK-DAG: [[DOUBLE:%[0-9a-zA-Z_]+]] = OpTypeFloat 64
// CHECK-DAG: [[V4DOUBLE:%[0-9a-zA-Z_]+]] = OpTypeVector [[DOUBLE]] 4
// CHECK-DAG: OpConvertSToF [[DOUBLE]] {{%[0-9a-zA-Z_]+}}
// CHECK-DAG: OpConvertSToF [[V4DOUBLE]]
// CHECK-DAG: OpConvertFToS [[V4I64]]
// CHECK-DAG: OpSelect [[V4DOUBLE]]

void kernel test(global int *in_i, global long4 *in_l4, global double *out_d,
                 global double4 *out_d4) {
  *out_d = convert_double(*in_i);
  out_d4[0] = convert_double4_rte(*in_l4);
  out_d4[1] = convert_double4_rtz(*in_l4);
}
