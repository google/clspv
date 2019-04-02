// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v2uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 2
// CHECK-DAG: %[[modmask:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 31
// CHECK-DAG: %[[vecmodmask:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[modmask]] %[[modmask]]
// CHECK-DAG: %[[scalarsize:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 32
// CHECK-DAG: %[[vecscalarbits:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[scalarsize]] %[[scalarsize]]
// CHECK:     %[[rotamount:[0-9]+]] = OpBitwiseAnd %[[v2uint]] {{.*}} %[[vecmodmask]]
// CHECK:     %[[downamount:[0-9]+]] = OpISub %[[v2uint]] %[[vecscalarbits]] %[[rotamount]]
// CHECK:     %[[hibits:[0-9]+]] = OpShiftLeftLogical %[[v2uint]] {{.*}} %[[rotamount]]
// CHECK:     %[[lobits:[0-9]+]] = OpShiftRightLogical %[[v2uint]] {{.*}} %[[downamount]]
// CHECK:     OpBitwiseOr %[[v2uint]] %[[lobits]] %[[hibits]]

kernel void test_rotate(global uint2* out, uint2 a, uint2 b)
{
    *out = rotate(a, b);
}

