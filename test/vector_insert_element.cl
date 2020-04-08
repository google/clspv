// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK: %[[LOAD_ARG0_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]]
// CHECK: %[[LOAD_ARG1_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: %[[COMPOSITE_INSERT_ID:[a-zA-Z0-9_]*]] = OpCompositeInsert %[[FLOAT_VECTOR_TYPE_ID]] %[[LOAD_ARG0_ID]] %[[LOAD_ARG1_ID]] 1
// CHECK:         OpStore  {{.*}} %[[COMPOSITE_INSERT_ID]] 

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(float a, global float4 *b) 
{
  (*b).y = a;
}
