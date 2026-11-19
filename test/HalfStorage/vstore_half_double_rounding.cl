// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --implicit-check-not="OpCapability Float16"
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void test_rounding(global half *out, double d) {
  // Double-rounding tie checks, subnormal ties, overflow, signed 0 / Inf / NaN.
  vstore_half(1.0 + 3.0 * 0x1p-11 - 0x1p-35, 0, out);
  vstore_half_rte(65520.0 - 0x1p-20, 1, out);
  vstore_half_rte(0x1p-25, 2, out);
  vstore_half_rte(3.0 * 0x1p-25, 3, out);
  vstore_half_rte(65520.0, 4, out);
  vstore_half_rtz(65536.0, 5, out);
  vstore_half_rtp(-0x1p-25, 6, out);
  vstore_half_rtn(-0x1p-25, 7, out);
  vstore_half_rtp(65505.0, 8, out);
  vstore_half_rte(-0.0, 9, out);
  vstore_half_rtz(__builtin_huge_val(), 10, out);
  vstore_half_rtn(__builtin_nan(""), 11, out);
  vstorea_half2_rtz((double2)(65536.0, -65536.0), 6, out);
  vstore_half_rtz(d, 14, out);
}

// CHECK-DAG: OpCapability Float64
// CHECK-DAG: [[double:%[^ ]+]] = OpTypeFloat 64
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[v2float:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[float_undef:%[^ ]+]] = OpUndef [[float]]{{$}}
// CHECK-DAG: [[double_65504:%[^ ]+]] = OpConstant [[double]] 65504{{$}}
// CHECK-DAG: [[float_1_00097656:%[^ ]+]] = OpConstant [[float]] 1.00097656{{$}}
// CHECK-DAG: [[float_65504:%[^ ]+]] = OpConstant [[float]] 65504{{$}}
// CHECK-DAG: [[float_n65504:%[^ ]+]] = OpConstant [[float]] -65504{{$}}
// CHECK-DAG: [[float_0:%[^ ]+]] = OpConstant [[float]] 0{{$}}
// CHECK-DAG: [[float_1_1920929en07:%[^ ]+]] = OpConstant [[float]] 1.1920929e-07{{$}}
// CHECK-DAG: [[float_0x1p_128:%[^ ]+]] = OpConstant [[float]] 0x1p+128{{$}}
// CHECK-DAG: [[float_n0:%[^ ]+]] = OpConstant [[float]] -0{{$}}
// CHECK-DAG: [[float_n5_96046448en08:%[^ ]+]] = OpConstant [[float]] -5.96046448e-08{{$}}
// CHECK-DAG: [[float_0x1_8p_128:%[^ ]+]] = OpConstant [[float]] 0x1.8p+128{{$}}
// CHECK-DAG: [[c_rte_tie:%[^ ]+]] = OpConstantComposite [[v2float]] [[float_1_00097656]] [[float_undef]]{{$}}
// CHECK-DAG: [[c_rte_max:%[^ ]+]] = OpConstantComposite [[v2float]] [[float_65504]] [[float_undef]]{{$}}
// CHECK-DAG: [[c_zero:%[^ ]+]] = OpConstantComposite [[v2float]] [[float_0]] [[float_undef]]{{$}}
// CHECK-DAG: [[c_sub_tie_odd:%[^ ]+]] = OpConstantComposite [[v2float]] [[float_1_1920929en07]] [[float_undef]]{{$}}
// CHECK-DAG: [[c_pinf:%[^ ]+]] = OpConstantComposite [[v2float]] [[float_0x1p_128]] [[float_undef]]{{$}}
// CHECK-DAG: [[c_nzero:%[^ ]+]] = OpConstantComposite [[v2float]] [[float_n0]] [[float_undef]]{{$}}
// CHECK-DAG: [[c_rtn_sub:%[^ ]+]] = OpConstantComposite [[v2float]] [[float_n5_96046448en08]] [[float_undef]]{{$}}
// CHECK-DAG: [[c_nan:%[^ ]+]] = OpConstantComposite [[v2float]] [[float_0x1_8p_128]] [[float_undef]]{{$}}
// CHECK-DAG: [[c_v2_rtz:%[^ ]+]] = OpConstantComposite [[v2float]] [[float_65504]] [[float_n65504]]{{$}}

// CHECK: OpExtInst {{.*}} PackHalf2x16 [[c_rte_tie]]
// CHECK: OpExtInst {{.*}} PackHalf2x16 [[c_rte_max]]
// CHECK: OpExtInst {{.*}} PackHalf2x16 [[c_zero]]
// CHECK: OpExtInst {{.*}} PackHalf2x16 [[c_sub_tie_odd]]
// CHECK: OpExtInst {{.*}} PackHalf2x16 [[c_pinf]]
// CHECK: OpExtInst {{.*}} PackHalf2x16 [[c_rte_max]]
// CHECK: OpExtInst {{.*}} PackHalf2x16 [[c_nzero]]
// CHECK: OpExtInst {{.*}} PackHalf2x16 [[c_rtn_sub]]
// CHECK: OpExtInst {{.*}} PackHalf2x16 [[c_pinf]]
// CHECK: OpExtInst {{.*}} PackHalf2x16 [[c_nzero]]
// CHECK: OpExtInst {{.*}} PackHalf2x16 [[c_pinf]]
// CHECK: OpExtInst {{.*}} PackHalf2x16 [[c_nan]]
// CHECK: OpExtInst {{.*}} PackHalf2x16 [[c_v2_rtz]]
// CHECK: OpFOrdGreaterThan {{.*}} [[double_65504]]
// CHECK: OpFConvert [[float]]
// CHECK: OpExtInst {{.*}} PackHalf2x16
