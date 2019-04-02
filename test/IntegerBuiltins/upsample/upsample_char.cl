// RUN: clspv  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[ushort_8:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 8
// CHECK-DAG: %[[ushort_42:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 42
// CHECK:     %[[hicast:[0-9]+]] = OpUConvert %[[ushort]] {{.*}}
// CHECK:     %[[hishifted:[0-9]+]] = OpShiftLeftLogical %[[ushort]] %[[hicast]] %[[ushort_8]]
// CHECK:     OpBitwiseOr %[[ushort]] %[[hishifted]] %[[ushort_42]]

kernel void test_upsample(global short* out, char a)
{
    *out = upsample(a, (uchar)42);
}

