// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv
// RUN: clspv %target -vec3-to-vec4 %s -o %t.novec3.spv
// RUN: spirv-val --target-env vulkan1.0 %t.novec3.spv
// RUN: clspv %target -O0 %s -o %t.o0.spv
// RUN: spirv-val --target-env vulkan1.0 %t.o0.spv

// CHECK-DAG: [[I64:%[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: [[V2I64:%[0-9a-zA-Z_]+]] = OpTypeVector [[I64]] 2
// CHECK-DAG: [[V4I64:%[0-9a-zA-Z_]+]] = OpTypeVector [[I64]] 4
// CHECK-DAG: [[DOUBLE:%[0-9a-zA-Z_]+]] = OpTypeFloat 64
// CHECK-DAG: [[V2DOUBLE:%[0-9a-zA-Z_]+]] = OpTypeVector [[DOUBLE]] 2
// CHECK-DAG: [[V3DOUBLE:%[0-9a-zA-Z_]+]] = OpTypeVector [[DOUBLE]] 3
// CHECK-DAG: [[V4DOUBLE:%[0-9a-zA-Z_]+]] = OpTypeVector [[DOUBLE]] 4
//
// Explicit rounding modes preserve libclc rounding-adjustment logic alongside
// base conversions (while rte lowers via base casts).
// CHECK: OpConvertSToF [[DOUBLE]]
// CHECK: OpConvertSToF [[DOUBLE]]
// CHECK: OpConvertFToS [[I64]]
// CHECK: OpSelect [[DOUBLE]]
// CHECK: OpConvertSToF [[DOUBLE]]
// CHECK: OpConvertFToS [[I64]]
// CHECK: OpSelect [[DOUBLE]]
// CHECK: OpConvertSToF [[DOUBLE]]
// CHECK: OpConvertFToS [[I64]]
// CHECK: OpSelect [[DOUBLE]]
// CHECK: OpConvertUToF [[V2DOUBLE]]
// CHECK: OpConvertFToU [[V2I64]]
// CHECK: OpSelect [[V2DOUBLE]]
// CHECK: OpConvertSToF [[V3DOUBLE]]
// CHECK: OpConvertSToF [[V4DOUBLE]]
// CHECK: OpConvertFToS [[V4I64]]
// CHECK: OpSelect [[V4DOUBLE]]

void kernel test(global long *l, global ulong2 *ul2, global long3 *l3,
                 global long4 *l4, global double *out1, global double2 *out2,
                 global double3 *out3, global double4 *out4) {
  out1[0] = convert_double_rte(*l);
  out1[1] = convert_double_rtz(*l);
  out1[2] = convert_double_rtp(*l);
  out1[3] = convert_double_rtn(*l);
  *out2 = convert_double2_rtz(*ul2);
  *out3 = convert_double3_rte(*l3);
  *out4 = convert_double4_rtp(*l4);
}
