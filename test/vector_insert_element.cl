// RUN: clspv %target %s -o %t.spv --spv-version=1.4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[UINT_0:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[UINT_1:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1
// CHECK: %[[LOAD_ARG0_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]]
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: [[insert:%[a-zA-Z0-9_]+]] = OpCompositeInsert %[[FLOAT_VECTOR_TYPE_ID]] %[[LOAD_ARG0_ID]] [[ld]] 1
// CHECK: OpStore {{.*}} [[insert]]
// TODO(#738): With vector combining disabled, the following optimization is not made.
// check: %[[ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain {{.*}} %[[UINT_0]] %[[UINT_0]] %[[UINT_1]]
// check:         OpStore %[[ACCESS_CHAIN_ID]] %[[LOAD_ARG0_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(float a, global float4 *b) 
{
  (*b).y = a;
}
