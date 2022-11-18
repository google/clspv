// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.5
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2spv1.5 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1
// CHECK-DAG: %[[CONSTANT_FLAG_ACQUIRE_RELEASE:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 72
// CHECK-DAG: %[[CONSTANT_FLAG_ACQUIRE:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 66
// CHECK-DAG: %[[CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 42
// CHECK-DAG: %[[CONSTANT_13_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 13
// CHECK: %[[ATOMIC_OP_ID:[a-zA-Z0-9_]*]] = OpAtomicCompareExchange %[[UINT_TYPE_ID]] {{.*}} %[[CONSTANT_1_ID]] %[[CONSTANT_FLAG_ACQUIRE_RELEASE]] %[[CONSTANT_FLAG_ACQUIRE]] %[[CONSTANT_42_ID]] %[[CONSTANT_13_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global int* b)
{
  *a = atomic_cmpxchg(b, 13, 42);
}
