// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[v4float:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 4
// CHECK-DAG: %[[v2float:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 2
// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[v4uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 4
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK:     OpConvertSToF %[[v2float]] %[[src_01:[0-9]+]]
// CHECK:     OpConvertSToF %[[v2float]] %[[src_23:[0-9]+]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* dst, global char4* src)
{
    *dst = convert_float4(*src);
}

