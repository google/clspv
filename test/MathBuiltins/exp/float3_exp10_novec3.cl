// RUN: clspv %target %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: %[[SHUFFLE:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT_VECTOR_TYPE_ID]] %[[LOADB_ID]]
// CHECK: %[[OP:[a-zA-Z0-9_]*]] = OpFunctionCall %[[FLOAT_VECTOR_TYPE_ID]] %{{.*}} %[[SHUFFLE]]
// CHECK: %[[OP_FINAL:[a-zA-Z0-9_]*]] = OpCompositeInsert %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: OpStore {{.*}} %[[OP_FINAL]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float3* a, global float3* b)
{
  *a = exp10(*b);
}
