// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 4
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[BOOL4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[BOOL_TYPE_ID]] 4
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT4_TYPE_ID]]
// CHECK: %[[BITCAST_TO_INT_ID:[a-zA-Z0-9_]*]] = OpBitcast %[[UINT4_TYPE_ID]] %[[LOADB_ID]]
// CHECK: %[[SIGN_BIT_ID:[a-zA-Z0-9_]*]] = OpBitwiseAnd %[[UINT4_TYPE_ID]] %[[BITCAST_TO_INT_ID]]
// CHECK: %[[COPYSIGN_ZERO_ID:[a-zA-Z0-9_]*]] = OpBitcast %[[FLOAT4_TYPE_ID]] %[[SIGN_BIT_ID]]
// CHECK: %[[CMP_GT_ID:[a-zA-Z0-9_]*]] = OpFOrdGreaterThan %[[BOOL4_TYPE_ID]] %[[LOADB_ID]]
// CHECK: %[[CMP_LT_ID:[a-zA-Z0-9_]*]] = OpFOrdLessThan %[[BOOL4_TYPE_ID]] %[[LOADB_ID]]
// CHECK: %[[CMP_EQ_ID:[a-zA-Z0-9_]*]] = OpFOrdEqual %[[BOOL4_TYPE_ID]] %[[LOADB_ID]]
// CHECK: %[[SEL_EQ_ID:[a-zA-Z0-9_]*]] = OpSelect %[[FLOAT4_TYPE_ID]] %[[CMP_EQ_ID]] %[[COPYSIGN_ZERO_ID]]
// CHECK: %[[SEL_LT_ID:[a-zA-Z0-9_]*]] = OpSelect %[[FLOAT4_TYPE_ID]] %[[CMP_LT_ID]] {{.*}} %[[SEL_EQ_ID]]
// CHECK: %[[SEL_GT_ID:[a-zA-Z0-9_]*]] = OpSelect %[[FLOAT4_TYPE_ID]] %[[CMP_GT_ID]] {{.*}} %[[SEL_LT_ID]]
// CHECK: OpStore {{.*}} %[[SEL_GT_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float4* b)
{
  *a = sign(*b);
}
