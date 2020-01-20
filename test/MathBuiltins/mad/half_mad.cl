// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[HALF_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 16
// CHECK-DAG: %[[CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[HALF_TYPE_ID]] 0x1.5p+5
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[HALF_TYPE_ID]] 0x1p+0
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[HALF_TYPE_ID]]
// CHECK: %[[MUL_ID:[a-zA-Z0-9_]*]] = OpFMul %[[HALF_TYPE_ID]] %[[LOADB_ID]] %[[CONSTANT_42_ID]]
// CHECK: %[[ADD_ID:[a-zA-Z0-9_]*]] = OpFAdd %[[HALF_TYPE_ID]] %[[MUL_ID]] %[[CONSTANT_1_ID]]
// CHECK: OpStore {{.*}} %[[ADD_ID]]

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global half* a, global half* b)
{
  *a = mad(*b, (half)42.0, (half)1.0);
}

