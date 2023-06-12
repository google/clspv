// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:     OpConvertFToU %[[ulong]]
// CHECK:     OpConvertFToU %[[ulong]]
// CHECK:     OpConvertFToU %[[ulong]]
// CHECK:     OpConvertFToU %[[ulong]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ulong4* dst, global float4* src)
{
    *dst = convert_ulong4_sat(*src);
}

