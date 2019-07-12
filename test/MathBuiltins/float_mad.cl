// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 42
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 1
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]]
// CHECK: %[[MUL_ID:[a-zA-Z0-9_]*]] = OpFMul %[[FLOAT_TYPE_ID]] %[[LOADB_ID]] %[[CONSTANT_42_ID]]
// CHECK: %[[ADD_ID:[a-zA-Z0-9_]*]] = OpFAdd %[[FLOAT_TYPE_ID]] %[[MUL_ID]] %[[CONSTANT_1_ID]]
// CHECK: OpStore {{.*}} %[[ADD_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global float* b)
{
  *a = mad(*b, 42.0f, 1.0f);
}
