// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: %[[EXTRACT_0:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[LOADB_ID]] 0
// CHECK: %[[OP_0:[a-zA-Z0-9_]*]] = OpFunctionCall %[[FLOAT_TYPE_ID]] %{{.*}} %[[EXTRACT_0]]
// CHECK: %[[EXTRACT_1:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[LOADB_ID]] 1
// CHECK: %[[OP_1:[a-zA-Z0-9_]*]] = OpFunctionCall %[[FLOAT_TYPE_ID]] %{{.*}} %[[EXTRACT_1]]
// CHECK: %[[OP_01:[a-zA-Z0-9_]*]] = OpCompositeConstruct
// CHECK: %[[EXTRACT_2:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[LOADB_ID]] 2
// CHECK: %[[OP_2:[a-zA-Z0-9_]*]] = OpFunctionCall %[[FLOAT_TYPE_ID]] %{{.*}} %[[EXTRACT_2]]
// CHECK: %[[EXTRACT_3:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[LOADB_ID]] 3
// CHECK: %[[OP_3:[a-zA-Z0-9_]*]] = OpFunctionCall %[[FLOAT_TYPE_ID]] %{{.*}} %[[EXTRACT_3]]
// CHECK: %[[OP_23:[a-zA-Z0-9_]*]] = OpCompositeConstruct
// CHECK: %[[OP_FINAL:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT_VECTOR_TYPE_ID]] %[[OP_01]] %[[OP_23]] 0 1 2 3
// CHECK: OpStore {{.*}} %[[OP_FINAL]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float4* b)
{
  *a = log2(*b);
}
