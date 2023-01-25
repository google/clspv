// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[HALF_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 16
// CHECK-DAG: %[[HALF3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[HALF_TYPE_ID]] 3
// CHECK: %[[LOADB0_ID:[a-zA-Z0-9_]*]] = OpLoad %[[HALF3_TYPE_ID]]
// CHECK: %[[LOADB1_ID:[a-zA-Z0-9_]*]] = OpLoad %[[HALF3_TYPE_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpDot %[[HALF_TYPE_ID]] %[[LOADB0_ID]] %[[LOADB1_ID]]
// CHECK: OpStore {{.*}} %[[OP_ID]]

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global half* a, global half3* b)
{
  *a = dot(b[0], b[1]);
}
