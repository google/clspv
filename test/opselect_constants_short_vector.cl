// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK:     %[[v2ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 2
// CHECK-DAG: %[[v2ushort_0:[0-9]+]] = OpConstantNull %[[v2ushort]]
// CHECK-DAG: %[[ushort_all_ones:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 65535
// CHECK-DAG: %[[v2ushort_all_ones:[0-9]+]] = OpConstantComposite %[[v2ushort]] %[[ushort_all_ones]] %[[ushort_all_ones]]
// CHECK:     OpSelect %[[v2ushort]] {{.*}} %[[v2ushort_all_ones]] %[[v2ushort_0]]

kernel void test(short2 A, short2 B, global short2 *dst)
{
    *dst = A >= B;
}

