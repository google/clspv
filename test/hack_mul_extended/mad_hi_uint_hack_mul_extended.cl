// RUN: clspv %target -int8 %s -o %t.spv -hack-mul-extended
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_16:%[^ ]+]] = OpConstant [[uint]] 16
// CHECK-DAG: [[uint_65535:%[^ ]+]] = OpConstant [[uint]] 65535
// CHECK-DAG: [[uint_4294901760:%[^ ]+]] = OpConstant [[uint]] 4294901760
// CHECK:     [[a:%[^ ]+]] = OpLoad [[uint]] {{.*}}
// CHECK:     [[b:%[^ ]+]] = OpLoad [[uint]] {{.*}}
// CHECK:     [[c:%[^ ]+]] = OpLoad [[uint]] {{.*}}
// CHECK:     [[a1:%[^ ]+]] = OpShiftRightLogical [[uint]] [[a]] [[uint_16]]
// CHECK:     [[b1:%[^ ]+]] = OpShiftRightLogical [[uint]] [[b]] [[uint_16]]
// CHECK:     [[a0:%[^ ]+]] = OpBitwiseAnd [[uint]] [[a]] [[uint_65535]]
// CHECK:     [[b0:%[^ ]+]] = OpBitwiseAnd [[uint]] [[b]] [[uint_65535]]
// CHECK:     [[a0b0:%[^ ]+]] = OpIMul [[uint]] [[b0]] [[a0]]
// CHECK:     [[a0b0_1:%[^ ]+]] = OpShiftRightLogical [[uint]] [[a0b0]] [[uint_16]]
// CHECK:     [[a1b0:%[^ ]+]] = OpIMul [[uint]] [[b0]] [[a1]]
// CHECK:     [[a1b0_1:%[^ ]+]] = OpShiftRightLogical [[uint]] [[a1b0]] [[uint_16]]
// CHECK:     [[a0b1:%[^ ]+]] = OpIMul [[uint]] [[b1]] [[a0]]
// CHECK:     [[a0b1_1:%[^ ]+]] = OpShiftRightLogical [[uint]] [[a0b1]] [[uint_16]]
// CHECK:     [[a1b1:%[^ ]+]] = OpIMul [[uint]] [[b1]] [[a1]]
// CHECK:     [[a1b1_1:%[^ ]+]] = OpBitwiseAnd [[uint]] [[a1b1]] [[uint_4294901760]]
// CHECK:     [[a1b0_0:%[^ ]+]] = OpBitwiseAnd [[uint]] [[a1b0]] [[uint_65535]]
// CHECK:     [[a0b1_0:%[^ ]+]] = OpBitwiseAnd [[uint]] [[a0b1]] [[uint_65535]]
// CHECK:     [[a1b1_0:%[^ ]+]] = OpBitwiseAnd [[uint]] [[a1b1]] [[uint_65535]]
// CHECK:     [[mul_lo_add:%[^ ]+]] = OpIAdd [[uint]] [[a0b0_1]] [[a1b0_0]]
// CHECK:     [[mul_lo_add2:%[^ ]+]] = OpIAdd [[uint]] [[mul_lo_add]] [[a0b1_0]]
// CHECK:     [[low_carry:%[^ ]+]] = OpShiftRightLogical [[uint]] [[mul_lo_add2]] [[uint_16]]
// CHECK:     [[add:%[^ ]+]] = OpIAdd [[uint]] [[a1b0_1]] [[c]]
// CHECK:     [[mul_hi_add:%[^ ]+]] = OpIAdd [[uint]] [[add]] [[a1b1_0]]
// CHECK:     [[mul_hi_add2:%[^ ]+]] = OpIAdd [[uint]] [[mul_hi_add]] [[a0b1_1]]
// CHECK:     [[mul_hi_no_carry:%[^ ]+]] = OpIAdd [[uint]] [[mul_hi_add2]] [[a1b1_1]]
// CHECK:     [[mul_hi:%[^ ]+]] = OpIAdd [[uint]] [[mul_hi_no_carry]] [[low_carry]]
// CHECK:     OpStore {{.*}} [[mul_hi]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint *a, global uint *b, global uint *c, global uint *d)
{
    *d = mad_hi(*a, *b, *c);
}

