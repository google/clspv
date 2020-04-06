// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 3
// CHECK: %[[UNDEF_ID:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: %[[SHUFFLE_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT_VECTOR_TYPE_ID]] %[[LOADA_ID]] %[[UNDEF_ID]] 2 0 1 
// CHECK: OpStore {{.*}} %[[SHUFFLE_ID]] 

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(float3 a, global float3 *b)
{
  (*b) = a.zxy;
}
