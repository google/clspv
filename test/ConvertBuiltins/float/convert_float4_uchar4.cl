// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[float4:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 4
// CHECK:     OpConvertUToF %[[float4]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* dst, global uchar4* src)
{
    *dst = convert_float4(*src);
}

