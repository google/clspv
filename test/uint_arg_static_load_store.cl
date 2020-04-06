// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, uint b)
{
// CHECK: %[[LOAD_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[UINT_TYPE_ID]]
// CHECK: OpStore {{.*}} %[[LOAD_ID]]
  *a = b;
}
