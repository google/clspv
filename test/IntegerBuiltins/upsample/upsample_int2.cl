// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v2ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 2
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v2uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 2
// CHECK-DAG: %[[ulong_32:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 32
// CHECK-DAG: %[[shiftamount:[0-9]+]] = OpConstantComposite %[[v2ulong]] %[[ulong_32]] %[[ulong_32]]
// CHECK-DAG: %[[ulong_42:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 42
// CHECK-DAG: %[[locst:[0-9]+]] = OpConstantComposite %[[v2ulong]] %[[ulong_42]] %[[ulong_42]]
// CHECK:     %[[hicast:[0-9]+]] = OpUConvert %[[v2ulong]] {{.*}}
// CHECK:     %[[hishifted:[0-9]+]] = OpShiftLeftLogical %[[v2ulong]] %[[hicast]] %[[shiftamount]]
// CHECK:     OpBitwiseOr %[[v2ulong]] %[[hishifted]] %[[locst]]

kernel void test_upsample(global long2* out, int2 a)
{
    *out = upsample(a, (uint2)42);
}

