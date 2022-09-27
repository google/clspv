// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uint_1:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1
// CHECK-DAG: %[[uint_80:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 80
// CHECK:     %[[__original_id_21:[0-9]+]] = OpAtomicIIncrement %[[uint]] %[[__original_id_19:[0-9]+]] %[[uint_1]] %[[uint_80]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, local int* b)
{
    *a = atomic_inc(b);
}

