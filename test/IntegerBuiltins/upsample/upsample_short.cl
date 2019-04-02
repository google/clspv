// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[uint_16:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 16
// CHECK-DAG: %[[uint_42:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 42
// CHECK:     %[[hicast:[0-9]+]] = OpUConvert %[[uint]] {{.*}}
// CHECK:     %[[hishifted:[0-9]+]] = OpShiftLeftLogical %[[uint]] %[[hicast]] %[[uint_16]]
// CHECK:     OpBitwiseOr %[[uint]] %[[hishifted]] %[[uint_42]]

kernel void test_upsample(global int* out, short a)
{
    *out = upsample(a, (ushort)42);
}

