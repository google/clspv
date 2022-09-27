// We use -O0 here because get_work_dim() always returns 3, and otherwise
// the compiler is smart enough to optimize everything away!
// RUN: clspv %target -O0 %s -o %t.spv -work-dim=0 -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK: %[[CONSTANT_3_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 3
// CHECK: %[[RESULT1_ID:[a-zA-Z0-9_]*]] = OpFunctionCall %[[UINT_TYPE_ID]] %[[GET_WORK_DIM_ID:[a-zA-Z0-9_]*]]
// CHECK: %[[RESULT2_ID:[a-zA-Z0-9_]*]] = OpFunctionCall %[[UINT_TYPE_ID]] %[[GET_WORK_DIM_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a)
{
  a[get_work_dim()] = get_work_dim();
}

// CHECK: %[[GET_WORK_DIM_ID]] = OpFunction %[[UINT_TYPE_ID]]
// CHECK: OpReturnValue %[[CONSTANT_3_ID]]
