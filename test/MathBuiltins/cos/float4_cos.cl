// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[FLOAT_VECTOR2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: %[[SHUFFLE_0:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT_VECTOR2_TYPE_ID]] %[[LOADB_ID]] {{.*}} 0 1
// CHECK: %[[OP_0:[a-zA-Z0-9_]*]] = OpFunctionCall %[[FLOAT_VECTOR2_TYPE_ID]] %{{.*}} %[[SHUFFLE_0]]
// CHECK: %[[SHUFFLE_1:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT_VECTOR2_TYPE_ID]] %[[LOADB_ID]] {{.*}} 2 3
// CHECK: %[[OP_1:[a-zA-Z0-9_]*]] = OpFunctionCall %[[FLOAT_VECTOR2_TYPE_ID]] %{{.*}} %[[SHUFFLE_1]]
// CHECK: %[[OP_FINAL:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: OpStore {{.*}} %[[OP_FINAL]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float4* b)
{
  *a = cos(*b);
}
