// RUN: clspv %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 3
// CHECK-DAG: %[[FLOAT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[UNDEF_FLOAT3:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT3_TYPE_ID]]
// CHECK-DAG: %[[UNDEF_FLOAT4:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT4_TYPE_ID]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT4_TYPE_ID]]
// CHECK: %[[SHUFFLEB_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT3_TYPE_ID]] %[[LOADB_ID]] %[[UNDEF_FLOAT4]] 0 1 2
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT3_TYPE_ID]] %[[EXT_INST]] Normalize %[[SHUFFLEB_ID]]
// CHECK: %[[SHUFFLEOP_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT4_TYPE_ID]] %[[OP_ID]] %[[UNDEF_FLOAT3]] 0 1 2 4294967295
// CHECK: OpStore {{.*}} %[[SHUFFLEOP_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float3* a, global float3* b)
{
  *a = normalize(*b);
}
