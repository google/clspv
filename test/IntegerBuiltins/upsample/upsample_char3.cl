// RUN: clspv %target  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v3ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 3
// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[v3uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 3
// CHECK-DAG: %[[ushort_8:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 8
// CHECK-DAG: %[[shiftamount:[0-9]+]] = OpConstantComposite %[[v3ushort]] %[[ushort_8]] %[[ushort_8]] %[[ushort_8]]
// CHECK-DAG: %[[ushort_42:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 42
// CHECK-DAG: %[[locst:[0-9]+]] = OpConstantComposite %[[v3ushort]] %[[ushort_42]] %[[ushort_42]] %[[ushort_42]]
// CHECK:     %[[hicast:[0-9]+]] = OpUConvert %[[v3ushort]] {{.*}}
// CHECK:     %[[hishifted:[0-9]+]] = OpShiftLeftLogical %[[v3ushort]] %[[hicast]] %[[shiftamount]]
// CHECK:     OpBitwiseOr %[[v3ushort]] %[[hishifted]] %[[locst]]

kernel void test_upsample(global short3* out, char3 a)
{
    *out = upsample(a, (uchar3)42);
}

