// RUN: clspv %target %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT_VECTOR3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 3
// CHECK-DAG: %[[UINT_VECTOR4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 4
// CHECK-DAG: %[[UNDEF_VECTOR3:[a-zA-Z0-9_]*]] = OpUndef %[[UINT_VECTOR3_TYPE_ID]]
// CHECK-DAG: %[[UNDEF_VECTOR4:[a-zA-Z0-9_]*]] = OpUndef %[[UINT_VECTOR4_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_31_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 31
// CHECK-DAG: [[vec31:%[a-zA-Z0-9_]*]] = OpConstantComposite %[[UINT_VECTOR3_TYPE_ID]] %[[CONSTANT_31_ID]] %[[CONSTANT_31_ID]] %[[CONSTANT_31_ID]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_VECTOR4_TYPE_ID]]
// CHECK: %[[LOADB_SHUFFLE:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[UINT_VECTOR3_TYPE_ID]] %[[LOADB_ID]] %[[UNDEF_VECTOR4]] 0 1 2
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[UINT_VECTOR3_TYPE_ID]] %[[EXT_INST]] FindUMsb %[[LOADB_SHUFFLE]]
// CHECK: %[[SUB_ID:[a-zA-Z0-9_]*]] = OpISub %[[UINT_VECTOR3_TYPE_ID]] [[vec31]] %[[OP_ID]]
// CHECK: %[[SUB_SHUFFLE:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[UINT_VECTOR4_TYPE_ID]] %[[SUB_ID]] %[[UNDEF_VECTOR3]] 0 1 2 4294967295
// CHECK: OpStore {{.*}} %[[SUB_SHUFFLE]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint3* a, global uint3* b)
{
  *a = clz(*b);
}
