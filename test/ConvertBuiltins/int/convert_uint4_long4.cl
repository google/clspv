// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uint4:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 4
// CHECK:     OpUConvert %[[uint4]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint4* dst, global long4* src)
{
    *dst = convert_uint4(*src);
}

