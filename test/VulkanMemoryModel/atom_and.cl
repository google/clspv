// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.5
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2spv1.5 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uint_1:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1
// CHECK-DAG: %[[CONSTANT_FLAG_ACQUIRE_RELEASE:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 72
// CHECK-DAG: %[[uint_42:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 42
// CHECK:     %[[__original_id_18:[0-9]+]] = OpAtomicAnd %[[uint]] {{.*}} %[[uint_1]] %[[CONSTANT_FLAG_ACQUIRE_RELEASE]] %[[uint_42]]
// CHECK:     OpStore {{.*}} %[[__original_id_18]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global int* b)
{
    *a = atom_and(b, 42);
}
