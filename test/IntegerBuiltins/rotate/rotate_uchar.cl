// RUN: clspv %target  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[modmask:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 7
// CHECK-DAG: %[[scalarsize:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 8
// CHECK:     %[[rotamount:[0-9]+]] = OpBitwiseAnd %[[uchar]] {{.*}} %[[modmask]]
// CHECK:     %[[downamountraw:[0-9]+]] = OpISub %[[uchar]] %[[scalarsize]] %[[rotamount]]
// CHECK:     %[[downamount:[0-9]+]] = OpBitwiseAnd %[[uchar]] %[[downamountraw]] %[[modmask]]
// CHECK:     %[[hibits:[0-9]+]] = OpShiftLeftLogical %[[uchar]] {{.*}} %[[rotamount]]
// CHECK:     %[[lobits:[0-9]+]] = OpShiftRightLogical %[[uchar]] {{.*}} %[[downamount]]
// CHECK:     OpBitwiseOr %[[uchar]] %[[lobits]] %[[hibits]]

kernel void test_rotate(global uchar* out, uchar a, uchar b)
{
    *out = rotate(a, b);
}


