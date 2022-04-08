// RUN: clspv -int8 %s -o %t.spv -hack-mul-extended
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[bool:%[^ ]+]] = OpTypeBool
// CHECK-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[ulong_0:%[^ ]+]] = OpConstant [[ulong]] 0
// CHECK-DAG: [[ulong_32:%[^ ]+]] = OpConstant [[ulong]] 32
// CHECK-DAG: [[ulong_4294967295:%[^ ]+]] = OpConstant [[ulong]] 4294967295
// CHECK-DAG: [[ulong_9223372032559808512:%[^ ]+]] = OpConstant [[ulong]] 9223372032559808512
// CHECK-DAG: [[ulong_18446744073709551615:%[^ ]+]] = OpConstant [[ulong]] 18446744073709551615
// CHECK-DAG: [[ulong_1:%[^ ]+]] = OpConstant [[ulong]] 1
// CHECK:     [[a:%[^ ]+]] = OpLoad [[ulong]] {{.*}}
// CHECK:     [[b:%[^ ]+]] = OpLoad [[ulong]] {{.*}}
// CHECK:     [[xor:%[^ ]+]] = OpBitwiseXor [[ulong]] [[b]] [[a]]
// CHECK:     [[res_neg:%[^ ]+]] = OpSLessThan [[bool]] [[xor]] [[ulong_0]]
// CHECK:     [[a_pos:%[^ ]+]] = OpExtInst [[ulong]] {{.*}} SAbs [[a]]
// CHECK:     [[b_pos:%[^ ]+]] = OpExtInst [[ulong]] {{.*}} SAbs [[b]]
// CHECK:     [[a1:%[^ ]+]] = OpShiftRightLogical [[ulong]] [[a_pos]] [[ulong_32]]
// CHECK:     [[b1:%[^ ]+]] = OpShiftRightLogical [[ulong]] [[b_pos]] [[ulong_32]]
// CHECK:     [[a0:%[^ ]+]] = OpBitwiseAnd [[ulong]] [[a_pos]] [[ulong_4294967295]]
// CHECK:     [[b0:%[^ ]+]] = OpBitwiseAnd [[ulong]] [[b_pos]] [[ulong_4294967295]]
// CHECK:     [[a0b0:%[^ ]+]] = OpIMul [[ulong]] [[b0]] [[a0]]
// CHECK:     [[a0b0_1:%[^ ]+]] = OpShiftRightLogical [[ulong]] [[a0b0]] [[ulong_32]]
// CHECK:     [[a1b0:%[^ ]+]] = OpIMul [[ulong]] [[b0]] [[a1]]
// CHECK:     [[a1b0_1:%[^ ]+]] = OpShiftRightLogical [[ulong]] [[a1b0]] [[ulong_32]]
// CHECK:     [[a0b1:%[^ ]+]] = OpIMul [[ulong]] [[b1]] [[a0]]
// CHECK:     [[a0b1_1:%[^ ]+]] = OpShiftRightLogical [[ulong]] [[a0b1]] [[ulong_32]]
// CHECK:     [[a1b1:%[^ ]+]] = OpIMul [[ulong]] [[b1]] [[a1]]
// CHECK:     [[a1b1_1:%[^ ]+]] = OpBitwiseAnd [[ulong]] [[a1b1]] [[ulong_9223372032559808512]]
// CHECK:     [[a0b0_0:%[^ ]+]] = OpBitwiseAnd [[ulong]] [[a0b0]] [[ulong_4294967295]]
// CHECK:     [[a1b0_0:%[^ ]+]] = OpBitwiseAnd [[ulong]] [[a1b0]] [[ulong_4294967295]]
// CHECK:     [[a0b1_0:%[^ ]+]] = OpBitwiseAnd [[ulong]] [[a0b1]] [[ulong_4294967295]]
// CHECK:     [[a1b1_0:%[^ ]+]] = OpBitwiseAnd [[ulong]] [[a1b1]] [[ulong_4294967295]]
// CHECK:     [[mul_lo_add:%[^ ]+]] = OpIAdd [[ulong]] [[a0b0_1]] [[a1b0_0]]
// CHECK:     [[mul_lo_add2:%[^ ]+]] = OpIAdd [[ulong]] [[mul_lo_add]] [[a0b1_0]]
// CHECK:     [[low_carry:%[^ ]+]] = OpShiftRightLogical [[ulong]] [[mul_lo_add2]] [[ulong_32]]
// CHECK:     [[mul_hi_add:%[^ ]+]] = OpIAdd [[ulong]] [[a1b1_0]] [[a1b0_1]]
// CHECK:     [[mul_hi_add2:%[^ ]+]] = OpIAdd [[ulong]] [[mul_hi_add]] [[a0b1_1]]
// CHECK:     [[mul_lo_hi:%[^ ]+]] = OpShiftLeftLogical [[ulong]] [[mul_lo_add2]] [[ulong_32]]
// CHECK:     [[mul_lo:%[^ ]+]] = OpBitwiseOr [[ulong]] [[mul_lo_hi]] [[a0b0_0]]
// CHECK:     [[mul_hi_no_carry:%[^ ]+]] = OpIAdd [[ulong]] [[mul_hi_add2]] [[a1b1_1]]
// CHECK:     [[mul_hi:%[^ ]+]] = OpIAdd [[ulong]] [[mul_hi_no_carry]] [[low_carry]]
// CHECK:     [[mul_lo_xor:%[^ ]+]] = OpBitwiseXor [[ulong]] [[mul_lo]] [[ulong_18446744073709551615]]
// CHECK:     [[add_carry:%[^ ]+]] = OpIAddCarry {{.*}} [[mul_lo_xor]] [[ulong_1]]
// CHECK:     [[carry:%[^ ]+]] = OpCompositeExtract [[ulong]] [[add_carry]] 1
// CHECK:     [[mul_hi_xor:%[^ ]+]] = OpBitwiseXor [[ulong]] [[mul_hi]] [[ulong_18446744073709551615]]
// CHECK:     [[mul_hi_inv:%[^ ]+]] = OpIAdd [[ulong]] [[carry]] [[mul_hi_xor]]
// CHECK:     [[select:%[^ ]+]] = OpSelect [[ulong]] [[res_neg]] [[mul_hi_inv]] [[mul_hi]]
// CHECK:     OpStore {{.*}} [[select]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global long *a, global long *b, global long *c)
{
    *c = mul_hi(*a, *b);
}

