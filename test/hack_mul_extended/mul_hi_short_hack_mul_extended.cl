// RUN: clspv -int8 %s -o %t.spv -hack-mul-extended
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[ushort:%[^ ]+]] = OpTypeInt 16 0
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_16:%[^ ]+]] = OpConstant [[uint]] 16
// CHECK:     [[a:%[^ ]+]] = OpLoad [[ushort]] {{.*}}
// CHECK:     [[b:%[^ ]+]] = OpLoad [[ushort]] {{.*}}
// CHECK:     [[a_ext:%[^ ]+]] = OpSConvert [[uint]] [[a]]
// CHECK:     [[b_ext:%[^ ]+]] = OpSConvert [[uint]] [[b]]
// CHECK:     [[mul:%[^ ]+]] = OpIMul [[uint]] [[b_ext]] [[a_ext]]
// CHECK:     [[shift:%[^ ]+]] = OpShiftRightLogical [[uint]] [[mul]] [[uint_16]]
// CHECK:     [[trunc:%[^ ]+]] = OpUConvert [[ushort]] [[shift]]
// CHECK:     OpStore {{.*}} [[trunc]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global short *a, global short *b, global short *c)
{
    *c = mul_hi(*a, *b);
}

