// RUN: clspv  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[v2uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 2
// CHECK-DAG: %[[modmask:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 7
// CHECK-DAG: %[[vecmodmask:[0-9]+]] = OpConstantComposite %[[v2uchar]] %[[modmask]] %[[modmask]]
// CHECK-DAG: %[[scalarsize:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 8
// CHECK-DAG: %[[vecscalarbits:[0-9]+]] = OpConstantComposite %[[v2uchar]] %[[scalarsize]] %[[scalarsize]]
// CHECK:     %[[rotamount:[0-9]+]] = OpBitwiseAnd %[[v2uchar]] {{.*}} %[[vecmodmask]]
// CHECK:     %[[downamountraw:[0-9]+]] = OpISub %[[v2uchar]] %[[vecscalarbits]] %[[rotamount]]
// CHECK:     %[[downamount:[0-9]+]] = OpBitwiseAnd %[[v2uchar]] %[[downamountraw]] %[[vecmodmask]]
// CHECK:     %[[hibits:[0-9]+]] = OpShiftLeftLogical %[[v2uchar]] {{.*}} %[[rotamount]]
// CHECK:     %[[lobits:[0-9]+]] = OpShiftRightLogical %[[v2uchar]] {{.*}} %[[downamount]]
// CHECK:     OpBitwiseOr %[[v2uchar]] %[[lobits]] %[[hibits]]

kernel void test_rotate(global uchar2* out, uchar2 a, uchar2 b)
{
    *out = rotate(a, b);
}


