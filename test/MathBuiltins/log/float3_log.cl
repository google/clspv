// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: %[[EXTRACT_0:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[LOADB_ID]] 0
// CHECK: OpFunctionCall %[[FLOAT_TYPE_ID]] %{{.*}} %[[EXTRACT_0]]
// CHECK: %[[EXTRACT_1:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[LOADB_ID]] 1
// CHECK: OpFunctionCall %[[FLOAT_TYPE_ID]] %{{.*}} %[[EXTRACT_1]]
// CHECK: OpCompositeConstruct
// CHECK: %[[OP_1:[a-zA-Z0-9_]*]] = OpFMul
// CHECK: %[[EXTRACT_2:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[LOADB_ID]] 2
// CHECK: OpFunctionCall %[[FLOAT_TYPE_ID]] %{{.*}} %[[EXTRACT_2]]
// CHECK: %[[OP_2:[a-zA-Z0-9_]*]] = OpFMul
// CHECK: OpCompositeInsert %[[FLOAT_VECTOR_TYPE_ID]] %{{.*}} 0
// CHECK: OpCompositeInsert %[[FLOAT_VECTOR_TYPE_ID]] %{{.*}} 1
// CHECK: %[[OP_FINAL:[a-zA-Z0-9_]*]] = OpCompositeInsert %[[FLOAT_VECTOR_TYPE_ID]] %{{.*}} 2
// CHECK: OpStore {{.*}} %[[OP_FINAL]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float3* a, global float3* b)
{
  *a = log(*b);
}
