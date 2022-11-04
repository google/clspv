// RUN: clspv %target -int8 %s -o %t.spv -hack-mul-extended
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[ulong2:%[^ ]+]] = OpTypeVector [[ulong]] 2
// CHECK-DAG: [[ulong_32:%[^ ]+]] = OpConstant [[ulong]] 32
// CHECK-DAG: [[ulong2_32:%[^ ]+]] = OpConstantComposite [[ulong2]] [[ulong_32]] [[ulong_32]]
// CHECK-DAG: [[ulong_4294967295:%[^ ]+]] = OpConstant [[ulong]] 4294967295
// CHECK-DAG: [[ulong2_4294967295:%[^ ]+]] = OpConstantComposite [[ulong2]] [[ulong_4294967295]] [[ulong_4294967295]]
// CHECK-DAG: [[ulong_18446744069414584320:%[^ ]+]] = OpConstant [[ulong]] 18446744069414584320
// CHECK-DAG: [[ulong2_18446744069414584320:%[^ ]+]] = OpConstantComposite [[ulong2]] [[ulong_18446744069414584320]] [[ulong_18446744069414584320]]
// CHECK:     [[a:%[^ ]+]] = OpLoad [[ulong2]] {{.*}}
// CHECK:     [[b:%[^ ]+]] = OpLoad [[ulong2]] {{.*}}
// CHECK:     [[a1:%[^ ]+]] = OpShiftRightLogical [[ulong2]] [[a]] [[ulong2_32]]
// CHECK:     [[b1:%[^ ]+]] = OpShiftRightLogical [[ulong2]] [[b]] [[ulong2_32]]
// CHECK:     [[a0:%[^ ]+]] = OpBitwiseAnd [[ulong2]] [[a]] [[ulong2_4294967295]]
// CHECK:     [[b0:%[^ ]+]] = OpBitwiseAnd [[ulong2]] [[b]] [[ulong2_4294967295]]
// CHECK:     [[a0b0:%[^ ]+]] = OpIMul [[ulong2]] [[b0]] [[a0]]
// CHECK:     [[a0b0_1:%[^ ]+]] = OpShiftRightLogical [[ulong2]] [[a0b0]] [[ulong2_32]]
// CHECK:     [[a1b0:%[^ ]+]] = OpIMul [[ulong2]] [[b0]] [[a1]]
// CHECK:     [[a1b0_1:%[^ ]+]] = OpShiftRightLogical [[ulong2]] [[a1b0]] [[ulong2_32]]
// CHECK:     [[a0b1:%[^ ]+]] = OpIMul [[ulong2]] [[b1]] [[a0]]
// CHECK:     [[a0b1_1:%[^ ]+]] = OpShiftRightLogical [[ulong2]] [[a0b1]] [[ulong2_32]]
// CHECK:     [[a1b1:%[^ ]+]] = OpIMul [[ulong2]] [[b1]] [[a1]]
// CHECK:     [[a1b1_1:%[^ ]+]] = OpBitwiseAnd [[ulong2]] [[a1b1]] [[ulong2_18446744069414584320]]
// CHECK:     [[a1b0_0:%[^ ]+]] = OpBitwiseAnd [[ulong2]] [[a1b0]] [[ulong2_4294967295]]
// CHECK:     [[a0b1_0:%[^ ]+]] = OpBitwiseAnd [[ulong2]] [[a0b1]] [[ulong2_4294967295]]
// CHECK:     [[a1b1_0:%[^ ]+]] = OpBitwiseAnd [[ulong2]] [[a1b1]] [[ulong2_4294967295]]
// CHECK:     [[mul_lo_add:%[^ ]+]] = OpIAdd [[ulong2]] [[a0b0_1]] [[a1b0_0]]
// CHECK:     [[mul_lo_add2:%[^ ]+]] = OpIAdd [[ulong2]] [[mul_lo_add]] [[a0b1_0]]
// CHECK:     [[low_carry:%[^ ]+]] = OpShiftRightLogical [[ulong2]] [[mul_lo_add2]] [[ulong2_32]]
// CHECK:     [[mul_hi_add:%[^ ]+]] = OpIAdd [[ulong2]] [[a1b1_0]] [[a1b0_1]]
// CHECK:     [[mul_hi_add2:%[^ ]+]] = OpIAdd [[ulong2]] [[mul_hi_add]] [[a0b1_1]]
// CHECK:     [[mul_hi_no_carry:%[^ ]+]] = OpIAdd [[ulong2]] [[mul_hi_add2]] [[a1b1_1]]
// CHECK:     [[mul_hi:%[^ ]+]] = OpIAdd [[ulong2]] [[mul_hi_no_carry]] [[low_carry]]
// CHECK:     OpStore {{.*}} [[mul_hi]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ulong2 *a, global ulong2 *b, global ulong2 *c)
{
    *c = mul_hi(*a, *b);
}

