// RUN: clspv %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 4
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[CONSTANT_31_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 31
// CHECK-DAG: %[[CONSTANT_COMPOSITE_31_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[UINT4_TYPE_ID]] %[[CONSTANT_31_ID]] %[[CONSTANT_31_ID]] %[[CONSTANT_31_ID]]
// CHECK: %[[B_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT4_TYPE_ID]]
// CHECK: %[[B_BITCAST_ID:[a-zA-Z0-9_]*]] = OpBitcast %[[UINT4_TYPE_ID]] %[[B_LOAD_ID]]
// CHECK: %[[ASHR_ID:[a-zA-Z0-9_]*]] = OpShiftRightArithmetic %[[UINT4_TYPE_ID]] %[[B_BITCAST_ID]] %[[CONSTANT_COMPOSITE_31_ID]]
// CHECK: OpStore {{.*}} %[[ASHR_ID]]
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int3* a, global float3* b)
{
  *a = signbit(b[0]);
}
