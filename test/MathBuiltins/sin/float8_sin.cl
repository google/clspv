// RUN: clspv %target %s --long-vector -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2
// CHECK-COUNT-8: OpLoad
// CHECK: OpCompositeConstruct %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK-NOT: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_TYPE_ID]] %{{.*}} Sin
// CHECK-DAG: OpCompositeConstruct %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK-DAG: OpCompositeConstruct %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK-DAG: OpCompositeConstruct %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK-DAG: OpFunctionCall %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK-DAG: OpFunctionCall %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK-DAG: OpFunctionCall %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK-DAG: OpFunctionCall %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK-COUNT-8: OpCompositeExtract %[[FLOAT_TYPE_ID]]
// CHECK-COUNT-8: OpStore

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float8* a, global float8* b)
{
  *a = sin(*b);
}
