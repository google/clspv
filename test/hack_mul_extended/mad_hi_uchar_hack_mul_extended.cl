// RUN: clspv %target -int8 %s -o %t.spv -hack-mul-extended
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[uchar:%[^ ]+]] = OpTypeInt 8 0
// CHECK-DAG: [[ushort:%[^ ]+]] = OpTypeInt 16 0
// CHECK-DAG: [[ushort_8:%[^ ]+]] = OpConstant [[ushort]] 8
// CHECK:     [[a:%[^ ]+]] = OpLoad [[uchar]] {{.*}}
// CHECK:     [[b:%[^ ]+]] = OpLoad [[uchar]] {{.*}}
// CHECK:     [[c:%[^ ]+]] = OpLoad [[uchar]] {{.*}}
// CHECK:     [[a_ext:%[^ ]+]] = OpUConvert [[ushort]] [[a]]
// CHECK:     [[b_ext:%[^ ]+]] = OpUConvert [[ushort]] [[b]]
// CHECK:     [[mul:%[^ ]+]] = OpIMul [[ushort]] [[b_ext]] [[a_ext]]
// CHECK:     [[shift:%[^ ]+]] = OpShiftRightLogical [[ushort]] [[mul]] [[ushort_8]]
// CHECK:     [[trunc:%[^ ]+]] = OpUConvert [[uchar]] [[shift]]
// CHECK:     [[add:%[^ ]+]] = OpIAdd [[uchar]] [[c]] [[trunc]]
// CHECK:     OpStore {{.*}} [[add]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uchar *a, global uchar *b, global uchar *c, global uchar *d)
{
    *d = mad_hi(*a, *b, *c);
}

