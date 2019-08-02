// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[FLOAT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2
// CHECK-DAG: %[[UINT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 2
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: %[[FLOAT4_UNDEF_ID:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT4_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1
// CHECK: %[[LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT4_TYPE_ID]]
// CHECK: %[[LO_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT2_TYPE_ID]] %[[LOAD_ID]] %[[FLOAT4_UNDEF_ID]] 0 1
// CHECK: %[[HI_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT2_TYPE_ID]] %[[LOAD_ID]] %[[FLOAT4_UNDEF_ID]] 2 3
// CHECK: %[[X_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[UINT_TYPE_ID]] {{.*}} PackHalf2x16 %[[LO_ID]]
// CHECK: %[[Y_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[UINT_TYPE_ID]] {{.*}} PackHalf2x16 %[[HI_ID]]
// CHECK: %[[INSERT_ID:[a-zA-Z0-9_]*]] = OpCompositeConstruct %[[UINT2_TYPE_ID]] %[[X_ID]] %[[Y_ID]]
// CHECK: %[[INSERT_BITCAST_ID:[a-zA-Z0-9_]*]] = OpBitcast %[[FLOAT2_TYPE_ID]] %[[INSERT_ID]]
// CHECK: %[[X_EXTRACTED_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[INSERT_BITCAST_ID]] 0
// CHECK: %[[Y_EXTRACTED_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[INSERT_BITCAST_ID]] 1
// CHECK: %[[A0_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain {{.*}} %[[ARG0_ID:[a-zA-Z0-9_]+]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: OpStore %[[A0_ACCESS_CHAIN_ID]] %[[X_EXTRACTED_ID]]
// CHECK: %[[A1_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain {{.*}} %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_1_ID]]
// CHECK: OpStore %[[A1_ACCESS_CHAIN_ID]] %[[Y_EXTRACTED_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float4* b)
{
  vstore_half4(*b, 0, (global half *)a);
}
