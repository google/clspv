// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v3ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 3
// CHECK-DAG: %[[modmask:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 15
// CHECK-DAG: %[[vecmodmask:[0-9]+]] = OpConstantComposite %[[v3ushort]] %[[modmask]] %[[modmask]] %[[modmask]]
// CHECK-DAG: %[[scalarsize:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 16
// CHECK-DAG: %[[vecscalarbits:[0-9]+]] = OpConstantComposite %[[v3ushort]] %[[scalarsize]] %[[scalarsize]] %[[scalarsize]]
// CHECK:     %[[rotamount:[0-9]+]] = OpBitwiseAnd %[[v3ushort]] {{.*}} %[[vecmodmask]]
// CHECK:     %[[downamountraw:[0-9]+]] = OpISub %[[v3ushort]] %[[vecscalarbits]] %[[rotamount]]
// CHECK:     %[[downamount:[0-9]+]] = OpBitwiseAnd %[[v3ushort]] %[[downamountraw]] %[[vecmodmask]]
// CHECK:     %[[hibits:[0-9]+]] = OpShiftLeftLogical %[[v3ushort]] {{.*}} %[[rotamount]]
// CHECK:     %[[lobits:[0-9]+]] = OpShiftRightLogical %[[v3ushort]] {{.*}} %[[downamount]]
// CHECK:     OpBitwiseOr %[[v3ushort]] %[[lobits]] %[[hibits]]

kernel void test_rotate(global ushort3* out, ushort3 a, ushort3 b)
{
    *out = rotate(a, b);
}

