// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[ulong_32:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 32
// CHECK-DAG: %[[ulong_42:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 42
// CHECK:     %[[hicast:[0-9]+]] = OpUConvert %[[ulong]] {{.*}}
// CHECK:     %[[hishifted:[0-9]+]] = OpShiftLeftLogical %[[ulong]] %[[hicast]] %[[ulong_32]]
// CHECK:     OpBitwiseOr %[[ulong]] %[[hishifted]] %[[ulong_42]]

kernel void test_upsample(global long* out, int a)
{
    *out = upsample(a, (uint)42);
}

