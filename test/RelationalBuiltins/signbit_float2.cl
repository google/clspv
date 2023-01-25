// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 2
// CHECK-DAG: %[[CONSTANT_31_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 31
// CHECK-DAG: %[[CONSTANT_COMPOSITE_31_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[UINT2_TYPE_ID]] %[[CONSTANT_31_ID]] %[[CONSTANT_31_ID]]
// CHECK: %[[B_BITCAST_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT2_TYPE_ID]]
// CHECK: %[[ASHR_ID:[a-zA-Z0-9_]*]] = OpShiftRightArithmetic %[[UINT2_TYPE_ID]] %[[B_BITCAST_ID]] %[[CONSTANT_COMPOSITE_31_ID]]
// CHECK: OpStore {{.*}} %[[ASHR_ID]]
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int2* a, global float2* b)
{
  *a = signbit(b[0]);
}
