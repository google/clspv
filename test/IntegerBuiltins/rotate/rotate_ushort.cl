// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[modmask:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 15
// CHECK-DAG: %[[scalarsize:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 16
// CHECK:     %[[rotamount:[0-9]+]] = OpBitwiseAnd %[[ushort]] {{.*}} %[[modmask]]
// CHECK:     %[[downamount:[0-9]+]] = OpISub %[[ushort]] %[[scalarsize]] %[[rotamount]]
// CHECK:     %[[hibits:[0-9]+]] = OpShiftLeftLogical %[[ushort]] {{.*}} %[[rotamount]]
// CHECK:     %[[lobits:[0-9]+]] = OpShiftRightLogical %[[ushort]] {{.*}} %[[downamount]]
// CHECK:     OpBitwiseOr %[[ushort]] %[[lobits]] %[[hibits]]

kernel void test_rotate(global ushort* out, ushort a, ushort b)
{
    *out = rotate(a, b);
}

