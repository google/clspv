// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0

// Workgroup
// CHECK-DAG: %[[CONSTANT_2_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 2

// Release | StorageBufferMemory
// CHECK-DAG: %[[CONSTANT_0x044_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 68

// CHECK: %[[FOO_ID]] = OpFunction
// CHECK: OpMemoryBarrier %[[CONSTANT_2_ID]] %[[CONSTANT_0x044_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo()
{
  write_mem_fence(CLK_GLOBAL_MEM_FENCE);
}
