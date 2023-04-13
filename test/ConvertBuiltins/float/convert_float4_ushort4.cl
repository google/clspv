// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK:     OpConvertUToF %[[float]]
// CHECK:     OpConvertUToF %[[float]]
// CHECK:     OpConvertUToF %[[float]]
// CHECK:     OpConvertUToF %[[float]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* dst, global ushort4* src)
{
    *dst = convert_float4(*src);
}

