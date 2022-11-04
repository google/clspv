// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 42
// CHECK-DAG: %[[CONSTANT_13_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 13
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a)
{
// CHECK: %[[LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad {{.*}}
  uint aLoad = *a;

// CHECK: %[[CMP_ID:[a-zA-Z0-9_]*]] = OpULessThan %[[BOOL_TYPE_ID]] %[[LOAD_ID]] %[[CONSTANT_42_ID]]
  const bool c = (aLoad < 42);

// CHECK: OpSelectionMerge %[[MERGE_LABEL_ID:[a-zA-Z0-9_]*]] None
// CHECK: OpBranchConditional %[[CMP_ID]] %[[IF_LABEL_ID:[a-zA-Z0-9_]*]] %[[MERGE_LABEL_ID]]
  if (c)
// CHECK: %[[IF_LABEL_ID]] = OpLabel
  {
// CHECK: OpStore {{.*}} %[[CONSTANT_13_ID]]
    *a = 13;
// CHECK: OpBranch %[[MERGE_LABEL_ID]]
  }
// CHECK: %[[MERGE_LABEL_ID]] = OpLabel
}
