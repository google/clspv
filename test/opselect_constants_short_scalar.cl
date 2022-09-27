// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[ushort_0:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 0
// CHECK-DAG: %[[ushort_1:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 1
// CHECK:     OpSelect %[[ushort]] {{.*}} %[[ushort_1]] %[[ushort_0]]

kernel void test(short A, short B, global short *dst)
{
    *dst = A >= B;
}

