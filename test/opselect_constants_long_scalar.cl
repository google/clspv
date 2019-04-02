// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[ulong_0:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 0
// CHECK-DAG: %[[ulong_1:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 1
// CHECK:     OpSelect %[[ulong]] {{.*}} %[[ulong_1]] %[[ulong_0]]

kernel void test(long A, long B, global long *dst)
{
    *dst = A >= B;
}

