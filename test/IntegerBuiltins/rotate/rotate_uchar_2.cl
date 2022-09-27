// RUN: clspv %target  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[uchar_2:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 2
// CHECK-DAG: %[[uchar_6:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 6
// CHECK:     %[[hibits:[0-9]+]] = OpShiftLeftLogical %[[uchar]] {{.*}} %[[uchar_2]]
// CHECK:     %[[lobits:[0-9]+]] = OpShiftRightLogical %[[uchar]] {{.*}} %[[uchar_6]]
// CHECK:     OpBitwiseOr %[[uchar]] %[[lobits]] %[[hibits]]

kernel void test_rotate(global uchar* out, uchar a)
{
    *out = rotate(a, (uchar)2);
}


