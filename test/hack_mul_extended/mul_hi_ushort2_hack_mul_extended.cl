// RUN: clspv -int8 %s -o %t.spv -hack-mul-extended
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[ushort:%[^ ]+]] = OpTypeInt 16 0
// CHECK-DAG: [[ushort2:%[^ ]+]] = OpTypeVector [[ushort]] 2
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint2:%[^ ]+]] = OpTypeVector [[uint]] 2
// CHECK-DAG: [[uint_16:%[^ ]+]] = OpConstant [[uint]] 16
// CHECK-DAG: [[uint2_16:%[^ ]+]] = OpConstantComposite [[uint2]] [[uint_16]] [[uint_16]]
// CHECK:     [[a:%[^ ]+]] = OpLoad [[ushort2]] {{.*}}
// CHECK:     [[b:%[^ ]+]] = OpLoad [[ushort2]] {{.*}}
// CHECK:     [[a_ext:%[^ ]+]] = OpUConvert [[uint2]] [[a]]
// CHECK:     [[b_ext:%[^ ]+]] = OpUConvert [[uint2]] [[b]]
// CHECK:     [[mul:%[^ ]+]] = OpIMul [[uint2]] [[b_ext]] [[a_ext]]
// CHECK:     [[shift:%[^ ]+]] = OpShiftRightLogical [[uint2]] [[mul]] [[uint2_16]]
// CHECK:     [[trunc:%[^ ]+]] = OpUConvert [[ushort2]] [[shift]]
// CHECK:     OpStore {{.*}} [[trunc]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ushort2 *a, global ushort2 *b, global ushort2 *c)
{
    *c = mul_hi(*a, *b);
}

