// RUN: clspv %s -o %t.spv -inline-entry-points -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_UNDEF:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[FLOAT4_UNDEF:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_FLOAT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 1
// CHECK-DAG: %[[COMPOSITE_FLOAT_1_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[FLOAT_VECTOR_TYPE_ID]] %[[CONSTANT_FLOAT_1_ID]] %[[CONSTANT_FLOAT_1_ID]] %[[CONSTANT_FLOAT_1_ID]] %[[FLOAT_UNDEF]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpFDiv %[[FLOAT_VECTOR_TYPE_ID]] %[[COMPOSITE_FLOAT_1_ID]] %[[LOADB_ID]]
// CHECK: %[[OP_ID4:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT_VECTOR_TYPE_ID]] %[[OP_ID]] %[[FLOAT4_UNDEF]] 0 1 2 4294967295
// CHECK: OpStore {{.*}} %[[OP_ID4]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float3* a, global float3* b)
{
  *a = half_recip(*b);
}
