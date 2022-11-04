// We have -O0 here to ensure local uint c is used.
// RUN: clspv %target -O0 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT_LOCAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer Workgroup %[[UINT_TYPE_ID]]
// CHECK: %[[C_ID:[a-zA-Z0-9_]*]] = OpVariable %[[UINT_LOCAL_POINTER_TYPE_ID]] Workgroup
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, global uint* b)
{
  local uint c;
// CHECK: %[[LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]]
// CHECK: OpStore %[[C_ID]] %[[LOAD_ID]]
  c = *a;
  *b = c;
}
