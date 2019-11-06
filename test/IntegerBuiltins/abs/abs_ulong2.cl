// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v2ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 2
// CHECK:     %[[__original_id_17:[0-9]+]] = OpLoad %[[v2ulong]]
// CHECK:     OpStore {{.*}} %[[__original_id_17]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ulong2* a, global ulong2* b)
{
    *a = abs(*b);
}

