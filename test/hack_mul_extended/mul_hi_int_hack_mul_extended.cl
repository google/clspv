// RUN: clspv %target -int8 %s -o %t.spv -hack-mul-extended
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[bool:%[^ ]+]] = OpTypeBool
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_16:%[^ ]+]] = OpConstant [[uint]] 16
// CHECK-DAG: [[uint_65535:%[^ ]+]] = OpConstant [[uint]] 65535
// CHECK-DAG: [[uint_2147418112:%[^ ]+]] = OpConstant [[uint]] 2147418112
// CHECK-DAG: [[uint_4294967295:%[^ ]+]] = OpConstant [[uint]] 4294967295
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK:     [[a:%[^ ]+]] = OpLoad [[uint]] {{.*}}
// CHECK:     [[b:%[^ ]+]] = OpLoad [[uint]] {{.*}}
// CHECK:     [[xor:%[^ ]+]] = OpBitwiseXor [[uint]] [[b]] [[a]]
// CHECK:     [[res_neg:%[^ ]+]] = OpSLessThan [[bool]] [[xor]] [[uint_0]]
// CHECK:     [[a_pos:%[^ ]+]] = OpExtInst [[uint]] {{.*}} SAbs [[a]]
// CHECK:     [[b_pos:%[^ ]+]] = OpExtInst [[uint]] {{.*}} SAbs [[b]]
// CHECK:     [[a1:%[^ ]+]] = OpShiftRightLogical [[uint]] [[a_pos]] [[uint_16]]
// CHECK:     [[b1:%[^ ]+]] = OpShiftRightLogical [[uint]] [[b_pos]] [[uint_16]]
// CHECK:     [[a0:%[^ ]+]] = OpBitwiseAnd [[uint]] [[a_pos]] [[uint_65535]]
// CHECK:     [[b0:%[^ ]+]] = OpBitwiseAnd [[uint]] [[b_pos]] [[uint_65535]]
// CHECK:     [[a0b0:%[^ ]+]] = OpIMul [[uint]] [[b0]] [[a0]]
// CHECK:     [[a0b0_1:%[^ ]+]] = OpShiftRightLogical [[uint]] [[a0b0]] [[uint_16]]
// CHECK:     [[a1b0:%[^ ]+]] = OpIMul [[uint]] [[b0]] [[a1]]
// CHECK:     [[a1b0_1:%[^ ]+]] = OpShiftRightLogical [[uint]] [[a1b0]] [[uint_16]]
// CHECK:     [[a0b1:%[^ ]+]] = OpIMul [[uint]] [[b1]] [[a0]]
// CHECK:     [[a0b1_1:%[^ ]+]] = OpShiftRightLogical [[uint]] [[a0b1]] [[uint_16]]
// CHECK:     [[a1b1:%[^ ]+]] = OpIMul [[uint]] [[b1]] [[a1]]
// CHECK:     [[a1b1_1:%[^ ]+]] = OpBitwiseAnd [[uint]] [[a1b1]] [[uint_2147418112]]
// CHECK:     [[a0b0_0:%[^ ]+]] = OpBitwiseAnd [[uint]] [[a0b0]] [[uint_65535]]
// CHECK:     [[a1b0_0:%[^ ]+]] = OpBitwiseAnd [[uint]] [[a1b0]] [[uint_65535]]
// CHECK:     [[a0b1_0:%[^ ]+]] = OpBitwiseAnd [[uint]] [[a0b1]] [[uint_65535]]
// CHECK:     [[a1b1_0:%[^ ]+]] = OpBitwiseAnd [[uint]] [[a1b1]] [[uint_65535]]
// CHECK:     [[mul_lo_add:%[^ ]+]] = OpIAdd [[uint]] [[a0b0_1]] [[a1b0_0]]
// CHECK:     [[mul_lo_add2:%[^ ]+]] = OpIAdd [[uint]] [[mul_lo_add]] [[a0b1_0]]
// CHECK:     [[low_carry:%[^ ]+]] = OpShiftRightLogical [[uint]] [[mul_lo_add2]] [[uint_16]]
// CHECK:     [[mul_hi_add:%[^ ]+]] = OpIAdd [[uint]] [[a1b1_0]] [[a1b0_1]]
// CHECK:     [[mul_hi_add2:%[^ ]+]] = OpIAdd [[uint]] [[mul_hi_add]] [[a0b1_1]]
// CHECK:     [[mul_lo_hi:%[^ ]+]] = OpShiftLeftLogical [[uint]] [[mul_lo_add2]] [[uint_16]]
// CHECK:     [[mul_lo:%[^ ]+]] = OpBitwiseOr [[uint]] [[mul_lo_hi]] [[a0b0_0]]
// CHECK:     [[mul_hi_no_carry:%[^ ]+]] = OpIAdd [[uint]] [[mul_hi_add2]] [[a1b1_1]]
// CHECK:     [[mul_hi:%[^ ]+]] = OpIAdd [[uint]] [[mul_hi_no_carry]] [[low_carry]]
// CHECK:     [[mul_lo_xor:%[^ ]+]] = OpBitwiseXor [[uint]] [[mul_lo]] [[uint_4294967295]]
// CHECK:     [[add_carry:%[^ ]+]] = OpIAddCarry {{.*}} [[mul_lo_xor]] [[uint_1]]
// CHECK:     [[carry:%[^ ]+]] = OpCompositeExtract [[uint]] [[add_carry]] 1
// CHECK:     [[mul_hi_xor:%[^ ]+]] = OpBitwiseXor [[uint]] [[mul_hi]] [[uint_4294967295]]
// CHECK:     [[mul_hi_inv:%[^ ]+]] = OpIAdd [[uint]] [[carry]] [[mul_hi_xor]]
// CHECK:     [[select:%[^ ]+]] = OpSelect [[uint]] [[res_neg]] [[mul_hi_inv]] [[mul_hi]]
// CHECK:     OpStore {{.*}} [[select]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int *a, global int *b, global int *c)
{
    *c = mul_hi(*a, *b);
}

