// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[modmask:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 63
// CHECK-DAG: %[[scalarsize:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 64
// CHECK:     %[[rotamount:[0-9]+]] = OpBitwiseAnd %[[ulong]] {{.*}} %[[modmask]]
// CHECK:     %[[downamount:[0-9]+]] = OpISub %[[ulong]] %[[scalarsize]] %[[rotamount]]
// CHECK:     %[[hibits:[0-9]+]] = OpShiftLeftLogical %[[ulong]] {{.*}} %[[rotamount]]
// CHECK:     %[[lobits:[0-9]+]] = OpShiftRightLogical %[[ulong]] {{.*}} %[[downamount]]
// CHECK:     OpBitwiseOr %[[ulong]] %[[lobits]] %[[hibits]]

kernel void test_rotate(global ulong* out, ulong a, ulong b)
{
    *out = rotate(a, b);
}

