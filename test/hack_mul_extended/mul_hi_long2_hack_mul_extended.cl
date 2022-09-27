// RUN: clspv %target -int8 %s -o %t.spv -hack-mul-extended
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[bool:%[^ ]+]] = OpTypeBool
// CHECK-DAG: [[bool2:%[^ ]+]] = OpTypeVector [[bool]] 2
// CHECK-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[ulong2:%[^ ]+]] = OpTypeVector [[ulong]] 2
// CHECK-DAG: [[ulong2_0:%[^ ]+]] = OpConstantNull [[ulong2]]
// CHECK-DAG: [[ulong_32:%[^ ]+]] = OpConstant [[ulong]] 32
// CHECK-DAG: [[ulong2_32:%[^ ]+]] = OpConstantComposite [[ulong2]] [[ulong_32]] [[ulong_32]]
// CHECK-DAG: [[ulong_4294967295:%[^ ]+]] = OpConstant [[ulong]] 4294967295
// CHECK-DAG: [[ulong2_4294967295:%[^ ]+]] = OpConstantComposite [[ulong2]] [[ulong_4294967295]] [[ulong_4294967295]]
// CHECK-DAG: [[ulong_18446744069414584320:%[^ ]+]] = OpConstant [[ulong]] 18446744069414584320
// CHECK-DAG: [[ulong2_18446744069414584320:%[^ ]+]] = OpConstantComposite [[ulong2]] [[ulong_18446744069414584320]] [[ulong_18446744069414584320]]
// CHECK-DAG: [[ulong_18446744073709551615:%[^ ]+]] = OpConstant [[ulong]] 18446744073709551615
// CHECK-DAG: [[ulong2_18446744073709551615:%[^ ]+]] = OpConstantComposite [[ulong2]] [[ulong_18446744073709551615]] [[ulong_18446744073709551615]]
// CHECK-DAG: [[ulong_1:%[^ ]+]] = OpConstant [[ulong]] 1
// CHECK-DAG: [[ulong2_1:%[^ ]+]] = OpConstantComposite [[ulong2]] [[ulong_1]] [[ulong_1]]
// CHECK:     [[a:%[^ ]+]] = OpLoad [[ulong2]] {{.*}}
// CHECK:     [[b:%[^ ]+]] = OpLoad [[ulong2]] {{.*}}
// CHECK:     [[xor:%[^ ]+]] = OpBitwiseXor [[ulong2]] [[b]] [[a]]
// CHECK:     [[res_neg:%[^ ]+]] = OpSLessThan [[bool2]] [[xor]] [[ulong2_0]]
// CHECK:     [[a_pos:%[^ ]+]] = OpExtInst [[ulong2]] {{.*}} SAbs [[a]]
// CHECK:     [[b_pos:%[^ ]+]] = OpExtInst [[ulong2]] {{.*}} SAbs [[b]]
// CHECK:     [[a1:%[^ ]+]] = OpShiftRightLogical [[ulong2]] [[a_pos]] [[ulong2_32]]
// CHECK:     [[b1:%[^ ]+]] = OpShiftRightLogical [[ulong2]] [[b_pos]] [[ulong2_32]]
// CHECK:     [[a0:%[^ ]+]] = OpBitwiseAnd [[ulong2]] [[a_pos]] [[ulong2_4294967295]]
// CHECK:     [[b0:%[^ ]+]] = OpBitwiseAnd [[ulong2]] [[b_pos]] [[ulong2_4294967295]]
// CHECK:     [[a0b0:%[^ ]+]] = OpIMul [[ulong2]] [[b0]] [[a0]]
// CHECK:     [[a0b0_1:%[^ ]+]] = OpShiftRightLogical [[ulong2]] [[a0b0]] [[ulong2_32]]
// CHECK:     [[a1b0:%[^ ]+]] = OpIMul [[ulong2]] [[b0]] [[a1]]
// CHECK:     [[a1b0_1:%[^ ]+]] = OpShiftRightLogical [[ulong2]] [[a1b0]] [[ulong2_32]]
// CHECK:     [[a0b1:%[^ ]+]] = OpIMul [[ulong2]] [[b1]] [[a0]]
// CHECK:     [[a0b1_1:%[^ ]+]] = OpShiftRightLogical [[ulong2]] [[a0b1]] [[ulong2_32]]
// CHECK:     [[a1b1:%[^ ]+]] = OpIMul [[ulong2]] [[b1]] [[a1]]
// CHECK:     [[a1b1_1:%[^ ]+]] = OpBitwiseAnd [[ulong2]] [[a1b1]] [[ulong2_18446744069414584320]]
// CHECK:     [[a0b0_0:%[^ ]+]] = OpBitwiseAnd [[ulong2]] [[a0b0]] [[ulong2_4294967295]]
// CHECK:     [[a1b0_0:%[^ ]+]] = OpBitwiseAnd [[ulong2]] [[a1b0]] [[ulong2_4294967295]]
// CHECK:     [[a0b1_0:%[^ ]+]] = OpBitwiseAnd [[ulong2]] [[a0b1]] [[ulong2_4294967295]]
// CHECK:     [[a1b1_0:%[^ ]+]] = OpBitwiseAnd [[ulong2]] [[a1b1]] [[ulong2_4294967295]]
// CHECK:     [[mul_lo_add:%[^ ]+]] = OpIAdd [[ulong2]] [[a0b0_1]] [[a1b0_0]]
// CHECK:     [[mul_lo_add2:%[^ ]+]] = OpIAdd [[ulong2]] [[mul_lo_add]] [[a0b1_0]]
// CHECK:     [[low_carry:%[^ ]+]] = OpShiftRightLogical [[ulong2]] [[mul_lo_add2]] [[ulong2_32]]
// CHECK:     [[mul_hi_add:%[^ ]+]] = OpIAdd [[ulong2]] [[a1b1_0]] [[a1b0_1]]
// CHECK:     [[mul_hi_add2:%[^ ]+]] = OpIAdd [[ulong2]] [[mul_hi_add]] [[a0b1_1]]
// CHECK:     [[mul_lo_hi:%[^ ]+]] = OpShiftLeftLogical [[ulong2]] [[mul_lo_add2]] [[ulong2_32]]
// CHECK:     [[mul_lo:%[^ ]+]] = OpBitwiseOr [[ulong2]] [[mul_lo_hi]] [[a0b0_0]]
// CHECK:     [[mul_hi_no_carry:%[^ ]+]] = OpIAdd [[ulong2]] [[mul_hi_add2]] [[a1b1_1]]
// CHECK:     [[mul_hi:%[^ ]+]] = OpIAdd [[ulong2]] [[mul_hi_no_carry]] [[low_carry]]
// CHECK:     [[mul_lo_xor:%[^ ]+]] = OpBitwiseXor [[ulong2]] [[mul_lo]] [[ulong2_18446744073709551615]]
// CHECK:     [[add_carry:%[^ ]+]] = OpIAddCarry {{.*}} [[mul_lo_xor]] [[ulong2_1]]
// CHECK:     [[carry:%[^ ]+]] = OpCompositeExtract [[ulong2]] [[add_carry]] 1
// CHECK:     [[mul_hi_xor:%[^ ]+]] = OpBitwiseXor [[ulong2]] [[mul_hi]] [[ulong2_18446744073709551615]]
// CHECK:     [[mul_hi_inv:%[^ ]+]] = OpIAdd [[ulong2]] [[carry]] [[mul_hi_xor]]
// CHECK:     [[select:%[^ ]+]] = OpSelect [[ulong2]] [[res_neg]] [[mul_hi_inv]] [[mul_hi]]
// CHECK:     OpStore {{.*}} [[select]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global long2 *a, global long2 *b, global long2 *c)
{
    *c = mul_hi(*a, *b);
}

