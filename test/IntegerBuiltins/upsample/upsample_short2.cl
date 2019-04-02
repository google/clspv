// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v2uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 2
// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v2ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 2
// CHECK-DAG: %[[uint_16:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 16
// CHECK-DAG: %[[shiftamount:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_16]] %[[uint_16]]
// CHECK-DAG: %[[uint_42:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 42
// CHECK-DAG: %[[locst:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_42]] %[[uint_42]]
// CHECK:     %[[hicast:[0-9]+]] = OpUConvert %[[v2uint]] {{.*}}
// CHECK:     %[[hishifted:[0-9]+]] = OpShiftLeftLogical %[[v2uint]] %[[hicast]] %[[shiftamount]]
// CHECK:     OpBitwiseOr %[[v2uint]] %[[hishifted]] %[[locst]]

kernel void test_upsample(global int2* out, short2 a)
{
    *out = upsample(a, (ushort2)42);
}

