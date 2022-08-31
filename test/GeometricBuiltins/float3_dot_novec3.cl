// RUN: clspv %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -vec3-to-vec4 --enable-opaque-pointers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 3
// CHECK-DAG: %[[FLOAT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[UNDEF_FLOAT4:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT4_TYPE_ID]]
// CHECK: %[[LOADB0_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT4_TYPE_ID]]
// CHECK: %[[LOADB1_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT4_TYPE_ID]]
// CHECK: %[[SHUFFLEB0_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT3_TYPE_ID]] %[[LOADB0_ID]] %[[UNDEF_FLOAT4]] 0 1 2
// CHECK: %[[SHUFFLEB1_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT3_TYPE_ID]] %[[LOADB1_ID]] %[[UNDEF_FLOAT4]] 0 1 2
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpDot %[[FLOAT_TYPE_ID]] %[[SHUFFLEB0_ID]] %[[SHUFFLEB1_ID]]
// CHECK: OpStore {{.*}} %[[OP_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global float3* b)
{
  *a = dot(b[0], b[1]);
}
