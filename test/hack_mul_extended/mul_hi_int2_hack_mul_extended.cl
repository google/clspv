// RUN: clspv -int8 %s -o %t.spv -hack-mul-extended
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[bool:%[^ ]+]] = OpTypeBool
// CHECK-DAG: [[bool2:%[^ ]+]] = OpTypeVector [[bool]] 2
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint2:%[^ ]+]] = OpTypeVector [[uint]] 2
// CHECK-DAG: [[uint2_0:%[^ ]+]] = OpConstantNull [[uint2]]
// CHECK-DAG: [[uint_16:%[^ ]+]] = OpConstant [[uint]] 16
// CHECK-DAG: [[uint2_16:%[^ ]+]] = OpConstantComposite [[uint2]] [[uint_16]] [[uint_16]]
// CHECK-DAG: [[uint_65535:%[^ ]+]] = OpConstant [[uint]] 65535
// CHECK-DAG: [[uint2_65535:%[^ ]+]] = OpConstantComposite [[uint2]] [[uint_65535]] [[uint_65535]]
// CHECK-DAG: [[uint_4294901760:%[^ ]+]] = OpConstant [[uint]] 4294901760
// CHECK-DAG: [[uint2_4294901760:%[^ ]+]] = OpConstantComposite [[uint2]] [[uint_4294901760]] [[uint_4294901760]]
// CHECK-DAG: [[uint_4294967295:%[^ ]+]] = OpConstant [[uint]] 4294967295
// CHECK-DAG: [[uint2_4294967295:%[^ ]+]] = OpConstantComposite [[uint2]] [[uint_4294967295]] [[uint_4294967295]]
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint2_1:%[^ ]+]] = OpConstantComposite [[uint2]] [[uint_1]] [[uint_1]]
// CHECK:     [[a:%[^ ]+]] = OpLoad [[uint2]] {{.*}}
// CHECK:     [[b:%[^ ]+]] = OpLoad [[uint2]] {{.*}}
// CHECK:     [[xor:%[^ ]+]] = OpBitwiseXor [[uint2]] [[b]] [[a]]
// CHECK:     [[res_neg:%[^ ]+]] = OpSLessThan [[bool2]] [[xor]] [[uint2_0]]
// CHECK:     [[a_pos:%[^ ]+]] = OpExtInst [[uint2]] {{.*}} SAbs [[a]]
// CHECK:     [[b_pos:%[^ ]+]] = OpExtInst [[uint2]] {{.*}} SAbs [[b]]
// CHECK:     [[a1:%[^ ]+]] = OpShiftRightLogical [[uint2]] [[a_pos]] [[uint2_16]]
// CHECK:     [[b1:%[^ ]+]] = OpShiftRightLogical [[uint2]] [[b_pos]] [[uint2_16]]
// CHECK:     [[a0:%[^ ]+]] = OpBitwiseAnd [[uint2]] [[a_pos]] [[uint2_65535]]
// CHECK:     [[b0:%[^ ]+]] = OpBitwiseAnd [[uint2]] [[b_pos]] [[uint2_65535]]
// CHECK:     [[a0b0:%[^ ]+]] = OpIMul [[uint2]] [[b0]] [[a0]]
// CHECK:     [[a0b0_1:%[^ ]+]] = OpShiftRightLogical [[uint2]] [[a0b0]] [[uint2_16]]
// CHECK:     [[a1b0:%[^ ]+]] = OpIMul [[uint2]] [[b0]] [[a1]]
// CHECK:     [[a1b0_1:%[^ ]+]] = OpShiftRightLogical [[uint2]] [[a1b0]] [[uint2_16]]
// CHECK:     [[a0b1:%[^ ]+]] = OpIMul [[uint2]] [[b1]] [[a0]]
// CHECK:     [[a0b1_1:%[^ ]+]] = OpShiftRightLogical [[uint2]] [[a0b1]] [[uint2_16]]
// CHECK:     [[a1b1:%[^ ]+]] = OpIMul [[uint2]] [[b1]] [[a1]]
// CHECK:     [[a1b1_1:%[^ ]+]] = OpBitwiseAnd [[uint2]] [[a1b1]] [[uint2_4294901760]]
// CHECK:     [[a0b0_0:%[^ ]+]] = OpBitwiseAnd [[uint2]] [[a0b0]] [[uint2_65535]]
// CHECK:     [[a1b0_0:%[^ ]+]] = OpBitwiseAnd [[uint2]] [[a1b0]] [[uint2_65535]]
// CHECK:     [[a0b1_0:%[^ ]+]] = OpBitwiseAnd [[uint2]] [[a0b1]] [[uint2_65535]]
// CHECK:     [[a1b1_0:%[^ ]+]] = OpBitwiseAnd [[uint2]] [[a1b1]] [[uint2_65535]]
// CHECK:     [[mul_lo_add:%[^ ]+]] = OpIAdd [[uint2]] [[a0b0_1]] [[a1b0_0]]
// CHECK:     [[mul_lo_add2:%[^ ]+]] = OpIAdd [[uint2]] [[mul_lo_add]] [[a0b1_0]]
// CHECK:     [[low_carry:%[^ ]+]] = OpShiftRightLogical [[uint2]] [[mul_lo_add2]] [[uint2_16]]
// CHECK:     [[mul_hi_add:%[^ ]+]] = OpIAdd [[uint2]] [[a1b1_0]] [[a1b0_1]]
// CHECK:     [[mul_hi_add2:%[^ ]+]] = OpIAdd [[uint2]] [[mul_hi_add]] [[a0b1_1]]
// CHECK:     [[mul_lo_hi:%[^ ]+]] = OpShiftLeftLogical [[uint2]] [[mul_lo_add2]] [[uint2_16]]
// CHECK:     [[mul_lo:%[^ ]+]] = OpBitwiseOr [[uint2]] [[mul_lo_hi]] [[a0b0_0]]
// CHECK:     [[mul_hi_no_carry:%[^ ]+]] = OpIAdd [[uint2]] [[mul_hi_add2]] [[a1b1_1]]
// CHECK:     [[mul_hi:%[^ ]+]] = OpIAdd [[uint2]] [[mul_hi_no_carry]] [[low_carry]]
// CHECK:     [[mul_lo_xor:%[^ ]+]] = OpBitwiseXor [[uint2]] [[mul_lo]] [[uint2_4294967295]]
// CHECK:     [[add_carry:%[^ ]+]] = OpIAddCarry {{.*}} [[mul_lo_xor]] [[uint2_1]]
// CHECK:     [[carry:%[^ ]+]] = OpCompositeExtract [[uint2]] [[add_carry]] 1
// CHECK:     [[mul_hi_xor:%[^ ]+]] = OpBitwiseXor [[uint2]] [[mul_hi]] [[uint2_4294967295]]
// CHECK:     [[mul_hi_inv:%[^ ]+]] = OpIAdd [[uint2]] [[carry]] [[mul_hi_xor]]
// CHECK:     [[select:%[^ ]+]] = OpSelect [[uint2]] [[res_neg]] [[mul_hi_inv]] [[mul_hi]]
// CHECK:     OpStore {{.*}} [[select]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int2 *a, global int2 *b, global int2 *c)
{
    *c = mul_hi(*a, *b);
}

