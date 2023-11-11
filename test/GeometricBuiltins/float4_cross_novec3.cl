// RUN: clspv %target %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[FLOAT3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 3

// CHECK: %[[FLOAT4_UNDEF_ID:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT4_TYPE_ID]]
// CHECK: %[[FLOAT3_UNDEF_ID:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT3_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 0
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT4_TYPE_ID]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT4_TYPE_ID]]
// CHECK: %[[SHUFFLEA_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT3_TYPE_ID]] %[[LOADA_ID]] %[[FLOAT4_UNDEF_ID]] 0 1 2
// CHECK: %[[SHUFFLEB_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT3_TYPE_ID]] %[[LOADB_ID]] %[[FLOAT4_UNDEF_ID]] 0 1 2
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT3_TYPE_ID]] %[[EXT_INST]] Cross %[[SHUFFLEA_ID]] %[[SHUFFLEB_ID]]
// CHECK: %[[SHUFFLEOP_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT4_TYPE_ID]] %[[OP_ID]] %[[FLOAT3_UNDEF_ID]] 0 1 2 4294967295
// CHECK: %[[INSERTOP_ID:[a-zA-Z0-9_]*]] = OpCompositeInsert %[[FLOAT4_TYPE_ID]] %[[FLOAT_CONSTANT_0_ID]] %[[SHUFFLEOP_ID]] 3
// CHECK: OpStore {{.*}} %[[INSERTOP_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float4* b)
{
  *a = cross(*a, *b);
}
