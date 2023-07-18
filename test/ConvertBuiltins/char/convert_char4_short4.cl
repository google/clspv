// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[uchar4:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 4
// CHECK:     OpUConvert %[[uchar4]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global char4* dst, global short4* src)
{
    *dst = convert_char4(*src);
}

