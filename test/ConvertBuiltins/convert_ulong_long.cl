// RUN: clspv -int8 %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ulong* dst, global long* src)
{
    *dst = convert_ulong(*src);
}

