// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 3
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT3_TYPE_ID]] %{{.*}} %{{.*}} 0 1 2
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT3_TYPE_ID]] %{{.*}} %{{.*}} 0 1 2
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT3_TYPE_ID]] %[[EXT_INST]] Cross %[[LOADA_ID]] %[[LOADB_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float3* a, global float3* b)
{
  *a = cross(*a, *b);
}
