// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 3
// CHECK-DAG: %[[v4float:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpLoad %[[v4float]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[v4float]]
// CHECK: %[[LOADC_ID:[a-zA-Z0-9_]*]] = OpLoad %[[v4float]]
// CHECK: %[[shufflea:[a-zA-Z0-9_]+]] = OpVectorShuffle %[[FLOAT_VECTOR_TYPE_ID]] %[[LOADA_ID]] %{{.*}} 0 1 2
// CHECK: %[[shuffleb:[a-zA-Z0-9_]+]] = OpVectorShuffle %[[FLOAT_VECTOR_TYPE_ID]] %[[LOADB_ID]] %{{.*}} 0 1 2
// CHECK: %[[shufflec:[a-zA-Z0-9_]+]] = OpVectorShuffle %[[FLOAT_VECTOR_TYPE_ID]] %[[LOADC_ID]] %{{.*}} 0 1 2
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_VECTOR_TYPE_ID]] %[[EXT_INST]] SmoothStep %[[shufflea]] %[[shuffleb]] %[[shufflec]]
// CHECK: %[[shuffle:[a-zA-Z0-9_]+]] = OpVectorShuffle %[[v4float]] %[[OP_ID]] %{{.*}} 0 1 2
// CHECK: OpStore {{.*}} %[[shuffle]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float3* a, global float3* b, global float3* c, global float3*o)
{
  *o = smoothstep(*a, *b, *c);
}
