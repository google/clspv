// RUN: clspv -int8 %s -o %t.spv -hack-mul-extended
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint2:%[^ ]+]] = OpTypeVector [[uint]] 2
// CHECK-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[ulong2:%[^ ]+]] = OpTypeVector [[ulong]] 2
// CHECK-DAG: [[ulong_32:%[^ ]+]] = OpConstant [[ulong]] 32
// CHECK-DAG: [[ulong2_32:%[^ ]+]] = OpConstantComposite [[ulong2]] [[ulong_32]] [[ulong_32]]
// CHECK:     [[a:%[^ ]+]] = OpLoad [[uint2]] {{.*}}
// CHECK:     [[b:%[^ ]+]] = OpLoad [[uint2]] {{.*}}
// CHECK:     [[a_ext:%[^ ]+]] = OpSConvert [[ulong2]] [[a]]
// CHECK:     [[b_ext:%[^ ]+]] = OpSConvert [[ulong2]] [[b]]
// CHECK:     [[mul:%[^ ]+]] = OpIMul [[ulong2]] [[b_ext]] [[a_ext]]
// CHECK:     [[shift:%[^ ]+]] = OpShiftRightLogical [[ulong2]] [[mul]] [[ulong2_32]]
// CHECK:     [[trunc:%[^ ]+]] = OpUConvert [[uint2]] [[shift]]
// CHECK:     OpStore {{.*}} [[trunc]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int2 *a, global int2 *b, global int2 *c)
{
    *c = mul_hi(*a, *b);
}

