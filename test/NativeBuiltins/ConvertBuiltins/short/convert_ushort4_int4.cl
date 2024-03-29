// RUN: clspv %target -int8 %s -o %t.spv --use-native-builtins=convert_ushort4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v4ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 4
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v4uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 4
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK:     %[[__original_id_23:[0-9]+]] = OpUConvert %[[v4ushort]] %[[__original_id_22:[0-9]+]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ushort4* dst, global int4* src)
{
    *dst = convert_ushort4(*src);
}

