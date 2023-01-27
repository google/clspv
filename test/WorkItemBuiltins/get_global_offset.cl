// RUN: clspv %target -O0 %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: OpFunctionCall %[[UINT_TYPE_ID]] %[[GET_GLOBAL_OFFSET_ID:[a-zA-Z0-9_]*]]
// CHECK: OpFunctionCall %[[UINT_TYPE_ID]] %[[GET_GLOBAL_OFFSET_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, uint b)
{
  a[get_global_offset(b)] = get_global_offset(3);
}

// CHECK: %[[GET_GLOBAL_OFFSET_ID]] = OpFunction %[[UINT_TYPE_ID]]
// CHECK: OpReturnValue %[[CONSTANT_0_ID]]
