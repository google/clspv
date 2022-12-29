// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[v4uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 4
// CHECK-DAG: %[[v2uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 2
// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v4ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 4
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK:     OpUConvert %[[v2uchar]] %[[src_01:[0-9]+]]
// CHECK:     OpUConvert %[[v2uchar]] %[[src_23:[0-9]+]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uchar4* dst, global ulong4* src)
{
    *dst = convert_uchar4(*src);
}

