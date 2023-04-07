// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:     OpSConvert %[[ulong]]
// CHECK:     OpSConvert %[[ulong]]
// CHECK:     OpSConvert %[[ulong]]
// CHECK:     OpSConvert %[[ulong]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global long4* dst, global int4* src)
{
    *dst = convert_long4(*src);
}

