// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v4uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 4
// CHECK-DAG: %[[v2uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 2
// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[v4float:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 4
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK:     OpConvertFToU %[[v2uint]] %[[src_01:[0-9]+]]
// CHECK:     OpConvertFToU %[[v2uint]] %[[src_23:[0-9]+]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint4* dst, global float4* src)
{
    *dst = convert_uint4(*src);
}

