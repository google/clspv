// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[ushort4:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 4
// CHECK:     OpUConvert %[[ushort4]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ushort4* dst, global uint4* src)
{
    *dst = convert_ushort4(*src);
}

