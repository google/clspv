// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v2ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 2
// CHECK-DAG: %[[modmask:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 15
// CHECK-DAG: %[[vecmodmask:[0-9]+]] = OpConstantComposite %[[v2ushort]] %[[modmask]] %[[modmask]]
// CHECK-DAG: %[[scalarsize:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 16
// CHECK-DAG: %[[vecscalarbits:[0-9]+]] = OpConstantComposite %[[v2ushort]] %[[scalarsize]] %[[scalarsize]]
// CHECK:     %[[rotamount:[0-9]+]] = OpBitwiseAnd %[[v2ushort]] {{.*}} %[[vecmodmask]]
// CHECK:     %[[downamount:[0-9]+]] = OpISub %[[v2ushort]] %[[vecscalarbits]] %[[rotamount]]
// CHECK:     %[[hibits:[0-9]+]] = OpShiftLeftLogical %[[v2ushort]] {{.*}} %[[rotamount]]
// CHECK:     %[[lobits:[0-9]+]] = OpShiftRightLogical %[[v2ushort]] {{.*}} %[[downamount]]
// CHECK:     OpBitwiseOr %[[v2ushort]] %[[lobits]] %[[hibits]]

kernel void test_rotate(global ushort2* out, ushort2 a, ushort2 b)
{
    *out = rotate(a, b);
}

