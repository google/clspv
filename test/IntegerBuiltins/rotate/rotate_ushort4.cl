// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v4ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 4
// CHECK-DAG: %[[modmask:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 15
// CHECK-DAG: %[[vecmodmask:[0-9]+]] = OpConstantComposite %[[v4ushort]] %[[modmask]] %[[modmask]] %[[modmask]] %[[modmask]]
// CHECK-DAG: %[[scalarsize:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 16
// CHECK-DAG: %[[vecscalarbits:[0-9]+]] = OpConstantComposite %[[v4ushort]] %[[scalarsize]] %[[scalarsize]] %[[scalarsize]] %[[scalarsize]]
// CHECK:     %[[rotamount:[0-9]+]] = OpBitwiseAnd %[[v4ushort]] {{.*}} %[[vecmodmask]]
// CHECK:     %[[downamountraw:[0-9]+]] = OpISub %[[v4ushort]] %[[vecscalarbits]] %[[rotamount]]
// CHECK:     %[[downamount:[0-9]+]] = OpBitwiseAnd %[[v4ushort]] %[[downamountraw]] %[[vecmodmask]]
// CHECK:     %[[hibits:[0-9]+]] = OpShiftLeftLogical %[[v4ushort]] {{.*}} %[[rotamount]]
// CHECK:     %[[lobits:[0-9]+]] = OpShiftRightLogical %[[v4ushort]] {{.*}} %[[downamount]]
// CHECK:     OpBitwiseOr %[[v4ushort]] %[[lobits]] %[[hibits]]

kernel void test_rotate(global ushort4* out, ushort4 a, ushort4 b)
{
    *out = rotate(a, b);
}

