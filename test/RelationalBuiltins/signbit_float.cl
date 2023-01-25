// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[CONSTANT_31_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 31
// CHECK: %[[B_BITCAST_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]]
// CHECK: %[[LSHR_ID:[a-zA-Z0-9_]*]] = OpShiftRightLogical %[[UINT_TYPE_ID]] %[[B_BITCAST_ID]] %[[CONSTANT_31_ID]]
// CHECK: OpStore {{.*}} %[[LSHR_ID]]
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global float* b)
{
  *a = signbit(b[0]);
}
