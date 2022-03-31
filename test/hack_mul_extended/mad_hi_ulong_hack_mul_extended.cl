// RUN: clspv -int8 %s -o %t.spv -hack-mul-extended
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[ulong_32:%[^ ]+]] = OpConstant [[ulong]] 32
// CHECK-DAG: [[ulong_4294967295:%[^ ]+]] = OpConstant [[ulong]] 4294967295
// CHECK-DAG: [[ulong_18446744069414584320:%[^ ]+]] = OpConstant [[ulong]] 18446744069414584320
// CHECK:     [[a:%[^ ]+]] = OpLoad [[ulong]] {{.*}}
// CHECK:     [[b:%[^ ]+]] = OpLoad [[ulong]] {{.*}}
// CHECK:     [[c:%[^ ]+]] = OpLoad [[ulong]] {{.*}}
// CHECK:     [[a1:%[^ ]+]] = OpShiftRightLogical [[ulong]] [[a]] [[ulong_32]]
// CHECK:     [[b1:%[^ ]+]] = OpShiftRightLogical [[ulong]] [[b]] [[ulong_32]]
// CHECK:     [[a0:%[^ ]+]] = OpBitwiseAnd [[ulong]] [[a]] [[ulong_4294967295]]
// CHECK:     [[b0:%[^ ]+]] = OpBitwiseAnd [[ulong]] [[b]] [[ulong_4294967295]]
// CHECK:     [[a0b0:%[^ ]+]] = OpIMul [[ulong]] [[b0]] [[a0]]
// CHECK:     [[a0b0_1:%[^ ]+]] = OpShiftRightLogical [[ulong]] [[a0b0]] [[ulong_32]]
// CHECK:     [[a1b0:%[^ ]+]] = OpIMul [[ulong]] [[b0]] [[a1]]
// CHECK:     [[a1b0_1:%[^ ]+]] = OpShiftRightLogical [[ulong]] [[a1b0]] [[ulong_32]]
// CHECK:     [[a0b1:%[^ ]+]] = OpIMul [[ulong]] [[b1]] [[a0]]
// CHECK:     [[a0b1_1:%[^ ]+]] = OpShiftRightLogical [[ulong]] [[a0b1]] [[ulong_32]]
// CHECK:     [[a1b1:%[^ ]+]] = OpIMul [[ulong]] [[b1]] [[a1]]
// CHECK:     [[a1b1_1:%[^ ]+]] = OpBitwiseAnd [[ulong]] [[a1b1]] [[ulong_18446744069414584320]]
// CHECK:     [[a1b0_0:%[^ ]+]] = OpBitwiseAnd [[ulong]] [[a1b0]] [[ulong_4294967295]]
// CHECK:     [[a0b1_0:%[^ ]+]] = OpBitwiseAnd [[ulong]] [[a0b1]] [[ulong_4294967295]]
// CHECK:     [[a1b1_0:%[^ ]+]] = OpBitwiseAnd [[ulong]] [[a1b1]] [[ulong_4294967295]]
// CHECK:     [[mul_lo_add:%[^ ]+]] = OpIAdd [[ulong]] [[a0b0_1]] [[a1b0_0]]
// CHECK:     [[mul_lo_add2:%[^ ]+]] = OpIAdd [[ulong]] [[mul_lo_add]] [[a0b1_0]]
// CHECK:     [[low_carry:%[^ ]+]] = OpShiftRightLogical [[ulong]] [[mul_lo_add2]] [[ulong_32]]
// CHECK:     [[add:%[^ ]+]] = OpIAdd [[ulong]] [[a1b0_1]] [[c]]
// CHECK:     [[mul_hi_add:%[^ ]+]] = OpIAdd [[ulong]] [[add]] [[a1b1_0]]
// CHECK:     [[mul_hi_add2:%[^ ]+]] = OpIAdd [[ulong]] [[mul_hi_add]] [[a0b1_1]]
// CHECK:     [[mul_hi_no_carry:%[^ ]+]] = OpIAdd [[ulong]] [[mul_hi_add2]] [[a1b1_1]]
// CHECK:     [[mul_hi:%[^ ]+]] = OpIAdd [[ulong]] [[mul_hi_no_carry]] [[low_carry]]
// CHECK:     OpStore {{.*}} [[mul_hi]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ulong *a, global ulong *b, global ulong *c, global ulong *d)
{
    *d = mad_hi(*a, *b, *c);
}

