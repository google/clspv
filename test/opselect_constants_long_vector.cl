// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK:     %[[v2ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 2
// CHECK-DAG: %[[v2ulong_0:[0-9]+]] = OpConstantNull %[[v2ulong]]
// CHECK-DAG: %[[ulong_all_ones:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 18446744073709551615
// CHECK-DAG: %[[v2ulong_all_ones:[0-9]+]] = OpConstantComposite %[[v2ulong]] %[[ulong_all_ones]] %[[ulong_all_ones]]
// CHECK:     OpSelect %[[v2ulong]] {{.*}} %[[v2ulong_all_ones]] %[[v2ulong_0]]

kernel void test(long2 A, long2 B, global long2 *dst)
{
    *dst = A >= B;
}

