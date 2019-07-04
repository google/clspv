// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[VEC_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[TYPE_ID]] 4
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float4* b)
{
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[VEC_TYPE_ID]]
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpLoad %[[VEC_TYPE_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpFDiv %[[VEC_TYPE_ID]] %[[LOADA_ID]] %[[LOADB_ID]]
// CHECK: OpStore {{.*}} %[[OP_ID]]
  *a /= *b;
}
