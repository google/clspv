// RUN: clspv -int8 %s -o %t.spv -hack-mul-extended
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[uchar:%[^ ]+]] = OpTypeInt 8 0
// CHECK-DAG: [[uchar2:%[^ ]+]] = OpTypeVector [[uchar]] 2
// CHECK-DAG: [[ushort:%[^ ]+]] = OpTypeInt 16 0
// CHECK-DAG: [[ushort2:%[^ ]+]] = OpTypeVector [[ushort]] 2
// CHECK-DAG: [[ushort_8:%[^ ]+]] = OpConstant [[ushort]] 8
// CHECK-DAG: [[ushort2_8:%[^ ]+]] = OpConstantComposite [[ushort2]] [[ushort_8]] [[ushort_8]]
// CHECK:     [[a:%[^ ]+]] = OpLoad [[uchar2]] {{.*}}
// CHECK:     [[b:%[^ ]+]] = OpLoad [[uchar2]] {{.*}}
// CHECK:     [[a_ext:%[^ ]+]] = OpSConvert [[ushort2]] [[a]]
// CHECK:     [[b_ext:%[^ ]+]] = OpSConvert [[ushort2]] [[b]]
// CHECK:     [[mul:%[^ ]+]] = OpIMul [[ushort2]] [[b_ext]] [[a_ext]]
// CHECK:     [[shift:%[^ ]+]] = OpShiftRightLogical [[ushort2]] [[mul]] [[ushort2_8]]
// CHECK:     [[trunc:%[^ ]+]] = OpUConvert [[uchar2]] [[shift]]
// CHECK:     OpStore {{.*}} [[trunc]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global char2 *a, global char2 *b, global char2 *c)
{
    *c = mul_hi(*a, *b);
}

