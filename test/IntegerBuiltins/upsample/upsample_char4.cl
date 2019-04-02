// RUN: clspv  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v4ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 4
// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[v4uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 4
// CHECK-DAG: %[[ushort_8:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 8
// CHECK-DAG: %[[shiftamount:[0-9]+]] = OpConstantComposite %[[v4ushort]] %[[ushort_8]] %[[ushort_8]] %[[ushort_8]] %[[ushort_8]]
// CHECK-DAG: %[[ushort_42:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 42
// CHECK-DAG: %[[locst:[0-9]+]] = OpConstantComposite %[[v4ushort]] %[[ushort_42]] %[[ushort_42]] %[[ushort_42]] %[[ushort_42]]
// CHECK:     %[[hicast:[0-9]+]] = OpUConvert %[[v4ushort]] {{.*}}
// CHECK:     %[[hishifted:[0-9]+]] = OpShiftLeftLogical %[[v4ushort]] %[[hicast]] %[[shiftamount]]
// CHECK:     OpBitwiseOr %[[v4ushort]] %[[hishifted]] %[[locst]]

kernel void test_upsample(global short4* out, char4 a)
{
    *out = upsample(a, (uchar4)42);
}


