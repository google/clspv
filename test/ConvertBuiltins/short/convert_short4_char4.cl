// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v4ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 4
// CHECK-DAG: %[[v2ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 2
// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[v4uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 4
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK:     OpSConvert %[[v2ushort]] %[[src_01:[0-9]+]]
// CHECK:     OpSConvert %[[v2ushort]] %[[src_23:[0-9]+]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global short4* dst, global char4* src)
{
    *dst = convert_short4(*src);
}

