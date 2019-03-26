// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uint_1:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1
// CHECK-DAG: %[[uint_80:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 80
// CHECK-DAG: %[[uint_42:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 42
// CHECK:     %[[__original_id_22:[0-9]+]] = OpAtomicAnd %[[uint]] %[[__original_id_20:[0-9]+]] %[[uint_1]] %[[uint_80]] %[[uint_42]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, local int* b)
{
    *a = atomic_and(b, 42);
}

