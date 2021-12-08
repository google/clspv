// RUN: clspv %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 4
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1
// CHECK-DAG: %[[COMPOSITE_1_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[UINT_VECTOR_TYPE_ID]] %[[CONSTANT_1_ID]] %[[CONSTANT_1_ID]] %[[CONSTANT_1_ID]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_VECTOR_TYPE_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[UINT_VECTOR_TYPE_ID]] %[[EXT_INST]] SMin %[[LOADB_ID]] %[[COMPOSITE_1_ID]]
// CHECK: OpStore {{.*}} %[[OP_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int3* a, global int3* b)
{
  *a = min(*b, 1);
}
