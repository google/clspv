// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:     %[[v2uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 2
// CHECK-DAG: %[[v2uint_0:[0-9]+]] = OpConstantNull %[[v2uint]]
// CHECK-DAG: %[[uint_all_ones:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967295
// CHECK-DAG: %[[v2uint_all_ones:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_all_ones]] %[[uint_all_ones]]
// CHECK:     OpSelect %[[v2uint]] {{.*}} %[[v2uint_all_ones]] %[[v2uint_0]]

kernel void test(int2 A, int2 B, global int2 *dst)
{
    *dst = A >= B;
}

