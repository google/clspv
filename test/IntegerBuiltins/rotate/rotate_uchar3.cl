// RUN: clspv %target  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[v3uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 3
// CHECK-DAG: %[[modmask:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 7
// CHECK-DAG: %[[vecmodmask:[0-9]+]] = OpConstantComposite %[[v3uchar]] %[[modmask]] %[[modmask]] %[[modmask]]
// CHECK-DAG: %[[scalarsize:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 8
// CHECK-DAG: %[[vecscalarbits:[0-9]+]] = OpConstantComposite %[[v3uchar]] %[[scalarsize]] %[[scalarsize]] %[[scalarsize]]
// CHECK:     %[[rotamount:[0-9]+]] = OpBitwiseAnd %[[v3uchar]] {{.*}} %[[vecmodmask]]
// CHECK:     %[[downamountraw:[0-9]+]] = OpISub %[[v3uchar]] %[[vecscalarbits]] %[[rotamount]]
// CHECK:     %[[downamount:[0-9]+]] = OpBitwiseAnd %[[v3uchar]] %[[downamountraw]] %[[vecmodmask]]
// CHECK:     %[[hibits:[0-9]+]] = OpShiftLeftLogical %[[v3uchar]] {{.*}} %[[rotamount]]
// CHECK:     %[[lobits:[0-9]+]] = OpShiftRightLogical %[[v3uchar]] {{.*}} %[[downamount]]
// CHECK:     OpBitwiseOr %[[v3uchar]] %[[lobits]] %[[hibits]]

kernel void test_rotate(global uchar3* out, uchar3 a, uchar3 b)
{
    *out = rotate(a, b);
}


