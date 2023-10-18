// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 3
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 3
// CHECK-DAG: %[[UINT_MAX_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 2147483647
// CHECK-DAG: %[[UINT3_MAX_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[UINT_VECTOR_TYPE_ID]] %[[UINT_MAX_ID]] %[[UINT_MAX_ID]] %[[UINT_MAX_ID]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: %[[BITCAST_ID:[a-zA-Z0-9_]*]] = OpBitcast %[[UINT_VECTOR_TYPE_ID]] %[[LOADB_ID]]
// CHECK: %[[AND_ID:[a-zA-Z0-9_]*]] = OpBitwiseAnd %[[UINT_VECTOR_TYPE_ID]] %[[BITCAST_ID]] %[[UINT3_MAX_ID]]
// CHECK: %[[BITCAST_ID:[a-zA-Z0-9_]*]] = OpBitcast %[[FLOAT_VECTOR_TYPE_ID]] %[[AND_ID]]
// CHECK: OpStore {{.*}} %[[BITCAST_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float3* a, global float3* b)
{
  *a = fabs(*b);
}
