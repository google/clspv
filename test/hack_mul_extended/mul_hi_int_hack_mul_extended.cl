// RUN: clspv -int8 %s -o %t.spv -hack-mul-extended
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[ulong_32:%[^ ]+]] = OpConstant [[ulong]] 32
// CHECK:     [[a:%[^ ]+]] = OpLoad [[uint]] {{.*}}
// CHECK:     [[b:%[^ ]+]] = OpLoad [[uint]] {{.*}}
// CHECK:     [[a_ext:%[^ ]+]] = OpSConvert [[ulong]] [[a]]
// CHECK:     [[b_ext:%[^ ]+]] = OpSConvert [[ulong]] [[b]]
// CHECK:     [[mul:%[^ ]+]] = OpIMul [[ulong]] [[b_ext]] [[a_ext]]
// CHECK:     [[shift:%[^ ]+]] = OpShiftRightLogical [[ulong]] [[mul]] [[ulong_32]]
// CHECK:     [[trunc:%[^ ]+]] = OpUConvert [[uint]] [[shift]]
// CHECK:     OpStore {{.*}} [[trunc]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int *a, global int *b, global int *c)
{
    *c = mul_hi(*a, *b);
}

