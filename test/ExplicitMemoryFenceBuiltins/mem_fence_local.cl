// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0

// Device
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1

// SequentiallyConsistent | WorkgroupMemory
// CHECK-DAG: %[[CONSTANT_0x110_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 272

// CHECK: %[[FOO_ID]] = OpFunction
// CHECK: OpMemoryBarrier %[[CONSTANT_1_ID]] %[[CONSTANT_0x110_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo()
{
  mem_fence(CLK_LOCAL_MEM_FENCE);
}
