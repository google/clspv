// RUN: clspv -int8 %s -o %t.spv -hack-mul-extended
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[uchar:%[^ ]+]] = OpTypeInt 8 0
// CHECK-DAG: [[ushort:%[^ ]+]] = OpTypeInt 16 0
// CHECK-DAG: [[ushort_8:%[^ ]+]] = OpConstant [[ushort]] 8
// CHECK:     [[a:%[^ ]+]] = OpLoad [[uchar]] {{.*}}
// CHECK:     [[b:%[^ ]+]] = OpLoad [[uchar]] {{.*}}
// CHECK:     [[a_ext:%[^ ]+]] = OpSConvert [[ushort]] [[a]]
// CHECK:     [[b_ext:%[^ ]+]] = OpSConvert [[ushort]] [[b]]
// CHECK:     [[mul:%[^ ]+]] = OpIMul [[ushort]] [[b_ext]] [[a_ext]]
// CHECK:     [[shift:%[^ ]+]] = OpShiftRightLogical [[ushort]] [[mul]] [[ushort_8]]
// CHECK:     [[trunc:%[^ ]+]] = OpUConvert [[uchar]] [[shift]]
// CHECK:     OpStore {{.*}} [[trunc]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global char *a, global char *b, global char *c)
{
    *c = mul_hi(*a, *b);
}

