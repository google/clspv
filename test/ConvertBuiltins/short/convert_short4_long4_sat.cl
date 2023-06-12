// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK:     OpUConvert %[[ushort]]
// CHECK:     OpUConvert %[[ushort]]
// CHECK:     OpUConvert %[[ushort]]
// CHECK:     OpUConvert %[[ushort]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global short4* dst, global long4* src)
{
    *dst = convert_short4_sat(*src);
}

