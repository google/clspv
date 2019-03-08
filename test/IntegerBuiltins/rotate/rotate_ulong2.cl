// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v2ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 2
// CHECK-DAG: %[[modmask:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 63
// CHECK-DAG: %[[vecmodmask:[0-9]+]] = OpConstantComposite %[[v2ulong]] %[[modmask]] %[[modmask]]
// CHECK-DAG: %[[scalarsize:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 64
// CHECK-DAG: %[[vecscalarbits:[0-9]+]] = OpConstantComposite %[[v2ulong]] %[[scalarsize]] %[[scalarsize]]
// CHECK:     %[[rotamount:[0-9]+]] = OpBitwiseAnd %[[v2ulong]] {{.*}} %[[vecmodmask]]
// CHECK:     %[[downamount:[0-9]+]] = OpISub %[[v2ulong]] %[[vecscalarbits]] %[[rotamount]]
// CHECK:     %[[hibits:[0-9]+]] = OpShiftLeftLogical %[[v2ulong]] {{.*}} %[[rotamount]]
// CHECK:     %[[lobits:[0-9]+]] = OpShiftRightLogical %[[v2ulong]] {{.*}} %[[downamount]]
// CHECK:     OpBitwiseOr %[[v2ulong]] %[[lobits]] %[[hibits]]

kernel void test_rotate(global ulong2* out, ulong2 a, ulong2 b)
{
    *out = rotate(a, b);
}

