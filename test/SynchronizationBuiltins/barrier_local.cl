// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0

// Workgroup
// CHECK-DAG: %[[CONSTANT_2_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 2

// SequentiallyConsistent | WorkgroupMemory
// CHECK-DAG: %[[CONSTANT_0x110_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 272

// CHECK: OpControlBarrier %[[CONSTANT_2_ID]] %[[CONSTANT_2_ID]] %[[CONSTANT_0x110_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo()
{
  barrier(CLK_LOCAL_MEM_FENCE);
}
