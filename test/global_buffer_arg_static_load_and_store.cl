// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] Binding 0
// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] Binding 1
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: %[[ARG0_ID]] = OpVariable {{.*}} StorageBuffer
// CHECK: %[[ARG1_ID]] = OpVariable {{.*}} StorageBuffer
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, global uint* b)
{
// CHECK: %[[STORE_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain {{.*}} %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOAD_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain {{.*}} %[[ARG1_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[LOAD_ACCESS_CHAIN_ID]]
// CHECK: OpStore %[[STORE_ACCESS_CHAIN_ID]] %[[LOAD_ID]]
  *a = *b;
}
