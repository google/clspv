// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[modmask:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 31
// CHECK-DAG: %[[scalarsize:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 32
// CHECK:     %[[rotamount:[0-9]+]] = OpBitwiseAnd %[[uint]] {{.*}} %[[modmask]]
// CHECK:     %[[downamountraw:[0-9]+]] = OpISub %[[uint]] %[[scalarsize]] %[[rotamount]]
// CHECK:     %[[downamount:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[downamountraw]] %[[modmask]]
// CHECK:     %[[hibits:[0-9]+]] = OpShiftLeftLogical %[[uint]] {{.*}} %[[rotamount]]
// CHECK:     %[[lobits:[0-9]+]] = OpShiftRightLogical %[[uint]] {{.*}} %[[downamount]]
// CHECK:     OpBitwiseOr %[[uint]] %[[lobits]] %[[hibits]]

kernel void test_rotate(global uint* out, uint a, uint b)
{
    *out = rotate(a, b);
}

