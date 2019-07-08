// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global int* b)
{
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]]
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]]
// CHECK: %[[IADD_ID:[a-zA-Z0-9_]*]] = OpIAdd %[[UINT_TYPE_ID]] %[[LOADA_ID]] %[[LOADB_ID]]
// CHECK: OpStore {{.*}} %[[IADD_ID]]
  *a += *b;
}
