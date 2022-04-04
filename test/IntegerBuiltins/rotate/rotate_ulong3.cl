// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v3ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 3
// CHECK-DAG: %[[modmask:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 63
// CHECK-DAG: %[[vecmodmask:[0-9]+]] = OpConstantComposite %[[v3ulong]] %[[modmask]] %[[modmask]] %[[modmask]]
// CHECK-DAG: %[[scalarsize:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 64
// CHECK-DAG: %[[vecscalarbits:[0-9]+]] = OpConstantComposite %[[v3ulong]] %[[scalarsize]] %[[scalarsize]] %[[scalarsize]]
// CHECK:     %[[rotamount:[0-9]+]] = OpBitwiseAnd %[[v3ulong]] {{.*}} %[[vecmodmask]]
// CHECK:     %[[downamountraw:[0-9]+]] = OpISub %[[v3ulong]] %[[vecscalarbits]] %[[rotamount]]
// CHECK:     %[[downamount:[0-9]+]] = OpBitwiseAnd %[[v3ulong]] %[[downamountraw]] %[[vecmodmask]]
// CHECK:     %[[hibits:[0-9]+]] = OpShiftLeftLogical %[[v3ulong]] {{.*}} %[[rotamount]]
// CHECK:     %[[lobits:[0-9]+]] = OpShiftRightLogical %[[v3ulong]] {{.*}} %[[downamount]]
// CHECK:     OpBitwiseOr %[[v3ulong]] %[[lobits]] %[[hibits]]

kernel void test_rotate(global ulong3* out, ulong3 a, ulong3 b)
{
    *out = rotate(a, b);
}

