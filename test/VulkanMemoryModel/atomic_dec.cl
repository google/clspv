// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.5
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2spv1.5 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1
// CHECK-DAG: %[[CONSTANT_FLAG_ACQUIRE_RELEASE:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 72
// CHECK: %[[ATOMIC_OP_ID:[a-zA-Z0-9_]*]] = OpAtomicIDecrement %[[UINT_TYPE_ID]] {{.*}} %[[CONSTANT_1_ID]] %[[CONSTANT_FLAG_ACQUIRE_RELEASE]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global int* b)
{
  *a = atomic_dec(b);
}
