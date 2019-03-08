// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v4uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 4
// CHECK-DAG: %[[modmask:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 31
// CHECK-DAG: %[[vecmodmask:[0-9]+]] = OpConstantComposite %[[v4uint]] %[[modmask]] %[[modmask]] %[[modmask]] %[[modmask]]
// CHECK-DAG: %[[scalarsize:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 32
// CHECK-DAG: %[[vecscalarbits:[0-9]+]] = OpConstantComposite %[[v4uint]] %[[scalarsize]] %[[scalarsize]] %[[scalarsize]] %[[scalarsize]]
// CHECK:     %[[rotamount:[0-9]+]] = OpBitwiseAnd %[[v4uint]] {{.*}} %[[vecmodmask]]
// CHECK:     %[[downamount:[0-9]+]] = OpISub %[[v4uint]] %[[vecscalarbits]] %[[rotamount]]
// CHECK:     %[[hibits:[0-9]+]] = OpShiftLeftLogical %[[v4uint]] {{.*}} %[[rotamount]]
// CHECK:     %[[lobits:[0-9]+]] = OpShiftRightLogical %[[v4uint]] {{.*}} %[[downamount]]
// CHECK:     OpBitwiseOr %[[v4uint]] %[[lobits]] %[[hibits]]

kernel void test_rotate(global uint4* out, uint4 a, uint4 b)
{
    *out = rotate(a, b);
}

