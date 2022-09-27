// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v4ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 4
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v4uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 4
// CHECK-DAG: %[[ulong_32:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 32
// CHECK-DAG: %[[shiftamount:[0-9]+]] = OpConstantComposite %[[v4ulong]] %[[ulong_32]] %[[ulong_32]] %[[ulong_32]] %[[ulong_32]]
// CHECK-DAG: %[[ulong_42:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 42
// CHECK-DAG: %[[locst:[0-9]+]] = OpConstantComposite %[[v4ulong]] %[[ulong_42]] %[[ulong_42]] %[[ulong_42]] %[[ulong_42]]
// CHECK:     %[[hicast:[0-9]+]] = OpUConvert %[[v4ulong]] {{.*}}
// CHECK:     %[[hishifted:[0-9]+]] = OpShiftLeftLogical %[[v4ulong]] %[[hicast]] %[[shiftamount]]
// CHECK:     OpBitwiseOr %[[v4ulong]] %[[hishifted]] %[[locst]]

kernel void test_upsample(global long4* out, int4 a)
{
    *out = upsample(a, (uint4)42);
}

