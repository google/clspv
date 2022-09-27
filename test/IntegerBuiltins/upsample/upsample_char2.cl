// RUN: clspv %target  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v2ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 2
// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[v2uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 2
// CHECK-DAG: %[[ushort_8:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 8
// CHECK-DAG: %[[shiftamount:[0-9]+]] = OpConstantComposite %[[v2ushort]] %[[ushort_8]] %[[ushort_8]]
// CHECK-DAG: %[[ushort_42:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 42
// CHECK-DAG: %[[locst:[0-9]+]] = OpConstantComposite %[[v2ushort]] %[[ushort_42]] %[[ushort_42]]
// CHECK:     %[[hicast:[0-9]+]] = OpUConvert %[[v2ushort]] {{.*}}
// CHECK:     %[[hishifted:[0-9]+]] = OpShiftLeftLogical %[[v2ushort]] %[[hicast]] %[[shiftamount]]
// CHECK:     OpBitwiseOr %[[v2ushort]] %[[hishifted]] %[[locst]]

kernel void test_upsample(global short2* out, char2 a)
{
    *out = upsample(a, (uchar2)42);
}


