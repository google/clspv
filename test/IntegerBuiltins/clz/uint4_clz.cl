// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 4
// CHECK-DAG: %[[CONSTANT_31_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 31
// CHECK-DAG: [[vec31:%[a-zA-Z0-9_]*]] = OpConstantComposite %[[UINT_VECTOR_TYPE_ID]] %[[CONSTANT_31_ID]] %[[CONSTANT_31_ID]] %[[CONSTANT_31_ID]] %[[CONSTANT_31_ID]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_VECTOR_TYPE_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[UINT_VECTOR_TYPE_ID]] %[[EXT_INST]] FindUMsb %[[LOADB_ID]]
// CHECK: %[[SUB_ID:[a-zA-Z0-9_]*]] = OpISub %[[UINT_VECTOR_TYPE_ID]] [[vec31]] %[[OP_ID]]
// CHECK: OpStore {{.*}} %[[SUB_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint4* a, global uint4* b)
{
  *a = clz(*b);
}
