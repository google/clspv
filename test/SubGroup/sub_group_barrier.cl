// RUN: clspv %s -cl-std=CL2.0 --spirv-std=1.5 -inline-entry-points -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0

// Subgroup
// CHECK-DAG: %[[CONSTANT_3_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 3
// Workgroup
// CHECK-DAG: %[[CONSTANT_2_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 2

// SequentiallyConsistent | WorkgroupMemory
// CHECK-DAG: %[[CONSTANT_0x110_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 272

// CHECK: OpControlBarrier %[[CONSTANT_3_ID]] %[[CONSTANT_2_ID]] %[[CONSTANT_0x110_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo()
{
  sub_group_barrier(CLK_LOCAL_MEM_FENCE);
}
