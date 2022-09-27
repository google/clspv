// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v2ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 2
// CHECK:     %[[__original_id_17:[0-9]+]] = OpLoad %[[v2ushort]]
// CHECK:     OpStore {{.*}} %[[__original_id_17]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ushort2* a, global ushort2* b)
{
    *a = abs(*b);
}

