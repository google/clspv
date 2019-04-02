// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v4ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 4
// CHECK-DAG: %[[modmask:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 63
// CHECK-DAG: %[[vecmodmask:[0-9]+]] = OpConstantComposite %[[v4ulong]] %[[modmask]] %[[modmask]] %[[modmask]] %[[modmask]]
// CHECK-DAG: %[[scalarsize:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 64
// CHECK-DAG: %[[vecscalarbits:[0-9]+]] = OpConstantComposite %[[v4ulong]] %[[scalarsize]] %[[scalarsize]] %[[scalarsize]] %[[scalarsize]]
// CHECK:     %[[rotamount:[0-9]+]] = OpBitwiseAnd %[[v4ulong]] {{.*}} %[[vecmodmask]]
// CHECK:     %[[downamount:[0-9]+]] = OpISub %[[v4ulong]] %[[vecscalarbits]] %[[rotamount]]
// CHECK:     %[[hibits:[0-9]+]] = OpShiftLeftLogical %[[v4ulong]] {{.*}} %[[rotamount]]
// CHECK:     %[[lobits:[0-9]+]] = OpShiftRightLogical %[[v4ulong]] {{.*}} %[[downamount]]
// CHECK:     OpBitwiseOr %[[v4ulong]] %[[lobits]] %[[hibits]]

kernel void test_rotate(global ulong4* out, ulong4 a, ulong4 b)
{
    *out = rotate(a, b);
}

