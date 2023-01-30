// RUN: clspv %target %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpDecorate %[[GLOBAL_ID_VAR_ID:[a-zA-Z0-9_]*]] BuiltIn GlobalInvocationId
// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-64-DAG: %[[ULONG_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 64 0
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 42
// CHECK: %[[GLOBAL_ID_VAR_ID]] = OpVariable {{.*}} Input
// CHECK: %[[ARG0_ID]] = OpVariable {{.*}} StorageBuffer
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a)
{
// CHECK-32: %[[ACCESS_CHAIN1_ID:[a-zA-Z0-9_]*]] = OpAccessChain {{.*}} %[[GLOBAL_ID_VAR_ID]] %[[CONSTANT_0_ID]]
// CHECK-64: %[[ACCESS_CHAIN1_ID:[a-zA-Z0-9_]*]] = OpAccessChain {{.*}} %[[GLOBAL_ID_VAR_ID]] %[[CONSTANT_0_ID]]
// CHECK:    %[[LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[ACCESS_CHAIN1_ID]]
// CHECK-64: %[[LOAD_ID_LONG:[a-zA-Z0-9_]*]] = OpUConvert %[[ULONG_TYPE_ID]] %[[LOAD_ID]]
// CHECK-64: %[[ACCESS_CHAIN2_ID:[a-zA-Z0-9_]*]] = OpAccessChain {{.*}} %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[LOAD_ID_LONG]]
// CHECK-32: %[[ACCESS_CHAIN2_ID:[a-zA-Z0-9_]*]] = OpAccessChain {{.*}} %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[LOAD_ID]]
// CHECK:    OpStore %[[ACCESS_CHAIN2_ID]] %[[CONSTANT_42_ID]]
  a[get_global_id(0)] = 42;
}
