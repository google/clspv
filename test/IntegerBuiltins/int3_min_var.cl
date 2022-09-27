// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 3
// CHECK: %[[CONSTANT_UNDEF_ID:[a-zA-Z0-9_]*]] = OpUndef %[[UINT_VECTOR_TYPE_ID]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_VECTOR_TYPE_ID]]
// CHECK: %[[LOADC_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]]
// CHECK: %[[COMPOSITE_INSERT_ID:[a-zA-Z0-9_]*]] = OpCompositeInsert %[[UINT_VECTOR_TYPE_ID]] %[[LOADC_ID]] %[[CONSTANT_UNDEF_ID]] 0
// CHECK: %[[VECTOR_SHUFFLE_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[UINT_VECTOR_TYPE_ID]] %[[COMPOSITE_INSERT_ID]] %[[CONSTANT_UNDEF_ID]] 0 0 0
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[UINT_VECTOR_TYPE_ID]] %[[EXT_INST]] SMin %[[LOADB_ID]] %[[VECTOR_SHUFFLE_ID]]
// CHECK: OpStore {{.*}} %[[OP_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int3* a, global int3* b, global int* c)
{
  *a = min(*b, *c);
}
