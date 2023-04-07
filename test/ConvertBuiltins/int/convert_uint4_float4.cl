// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:     OpConvertFToU %[[uint]]
// CHECK:     OpConvertFToU %[[uint]]
// CHECK:     OpConvertFToU %[[uint]]
// CHECK:     OpConvertFToU %[[uint]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint4* dst, global float4* src)
{
    *dst = convert_uint4(*src);
}

