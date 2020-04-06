// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_4_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[FLOAT_2_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2
// CHECK: %[[UNDEF_ID:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT_4_VECTOR_TYPE_ID]]
// CHECK: %[[LOAD_ARG0_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_4_VECTOR_TYPE_ID]]
// CHECK: %[[VECTOR_SHUFFLE_HI_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT_2_VECTOR_TYPE_ID]] %[[LOAD_ARG0_ID]] %[[UNDEF_ID]] 2 3 
// CHECK: OpStore {{.*}} %[[VECTOR_SHUFFLE_HI_ID]] 
// CHECK: %[[VECTOR_SHUFFLE_LO_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT_2_VECTOR_TYPE_ID]] %[[LOAD_ARG0_ID]] %[[UNDEF_ID]] 0 1 
// CHECK: OpStore {{.*}} %[[VECTOR_SHUFFLE_LO_ID]] 

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(float4 a, global float2 *b, global float2 *c)
{
  (*b) = a.hi;
  (*c) = a.lo;
}
