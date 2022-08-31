// RUN: clspv %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -vec3-to-vec4 --enable-opaque-pointers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 4
// CHECK-DAG: %[[CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 42
// CHECK-DAG: %[[COMPOSITE_42_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[UINT_VECTOR_TYPE_ID]] %[[CONSTANT_42_ID]] %[[CONSTANT_42_ID]]
// CHECK-DAG: %[[CONSTANT_3_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 3
// CHECK-DAG: %[[COMPOSITE_3_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[UINT_VECTOR_TYPE_ID]] %[[CONSTANT_3_ID]] %[[CONSTANT_3_ID]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_VECTOR_TYPE_ID]]
// CHECK: %[[MUL_ID:[a-zA-Z0-9_]*]] = OpIMul %[[UINT_VECTOR_TYPE_ID]] %[[LOADB_ID]] %[[COMPOSITE_42_ID]]
// CHECK: %[[ADD_ID:[a-zA-Z0-9_]*]] = OpIAdd %[[UINT_VECTOR_TYPE_ID]] %[[MUL_ID]] %[[COMPOSITE_3_ID]]
// CHECK: OpStore {{.*}} %[[ADD_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint3* a, global uint3* b)
{
  *a = mad24(*b, (uint)42, (uint)3);
}
