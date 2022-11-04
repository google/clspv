// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 3
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 3
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[BOOL3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[BOOL_TYPE_ID]] 3
// CHECK-DAG: %[[UINT3_CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstantNull %[[UINT3_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_ALL_BITS_SET_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 4294967295
// CHECK-DAG: %[[UINT3_CONSTANT_ALL_BITS_SET_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[UINT3_TYPE_ID]] %[[CONSTANT_ALL_BITS_SET_ID]] %[[CONSTANT_ALL_BITS_SET_ID]] %[[CONSTANT_ALL_BITS_SET_ID]]
// CHECK: %[[B0_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT3_TYPE_ID]]
// CHECK: %[[B1_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT3_TYPE_ID]]
// CHECK: %[[CMP_ID:[a-zA-Z0-9_]*]] = OpFOrdEqual %[[BOOL3_TYPE_ID]] %[[B0_LOAD_ID]] %[[B1_LOAD_ID]]
// CHECK: %[[CAS_ID:[a-zA-Z0-9_]*]] = OpSelect %[[UINT3_TYPE_ID]] %[[CMP_ID]] %[[UINT3_CONSTANT_ALL_BITS_SET_ID]] %[[UINT3_CONSTANT_0_ID]]
// CHECK: OpStore {{.*}} %[[CAS_ID]]
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int3* a, global float3* b)
{
  *a = isequal(b[0], b[1]);
}
