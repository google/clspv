// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v3uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 3
// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v3ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 3
// CHECK-DAG: %[[uint_16:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 16
// CHECK-DAG: %[[shiftamount:[0-9]+]] = OpConstantComposite %[[v3uint]] %[[uint_16]] %[[uint_16]] %[[uint_16]]
// CHECK-DAG: %[[uint_42:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 42
// CHECK-DAG: %[[locst:[0-9]+]] = OpConstantComposite %[[v3uint]] %[[uint_42]] %[[uint_42]] %[[uint_42]]
// CHECK:     %[[hicast:[0-9]+]] = OpUConvert %[[v3uint]] {{.*}}
// CHECK:     %[[hishifted:[0-9]+]] = OpShiftLeftLogical %[[v3uint]] %[[hicast]] %[[shiftamount]]
// CHECK:     OpBitwiseOr %[[v3uint]] %[[hishifted]] %[[locst]]

kernel void test_upsample(global int3* out, short3 a)
{
    *out = upsample(a, (ushort3)42);
}

