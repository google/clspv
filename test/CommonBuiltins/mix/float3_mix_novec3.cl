// RUN: clspv %target %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_VECTOR3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 3
// CHECK-DAG: %[[FLOAT_VECTOR4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[UNDEF_VECTOR3:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT_VECTOR3_TYPE_ID]]
// CHECK-DAG: %[[UNDEF_VECTOR4:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT_VECTOR4_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_FLOAT_0_5_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 0.5
// CHECK-DAG: %[[COMPOSITE_FLOAT_0_5_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[FLOAT_VECTOR3_TYPE_ID]] %[[CONSTANT_FLOAT_0_5_ID]] %[[CONSTANT_FLOAT_0_5_ID]] %[[CONSTANT_FLOAT_0_5_ID]]
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR4_TYPE_ID]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR4_TYPE_ID]]
// CHECK: %[[SHUFFLEA_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT_VECTOR3_TYPE_ID]] %[[LOADA_ID]] %[[UNDEF_VECTOR4]] 0 1 2
// CHECK: %[[SHUFFLEB_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT_VECTOR3_TYPE_ID]] %[[LOADB_ID]] %[[UNDEF_VECTOR4]] 0 1 2
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_VECTOR3_TYPE_ID]] %[[EXT_INST]] FMix %[[SHUFFLEA_ID]] %[[SHUFFLEB_ID]] %[[COMPOSITE_FLOAT_0_5_ID]]
// CHECK: %[[SHUFFLEOP_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT_VECTOR4_TYPE_ID]] %[[OP_ID]] %[[UNDEF_VECTOR3]] 0 1 2 4294967295
// CHECK: OpStore {{.*}} %[[SHUFFLEOP_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float3* a, global float3* b)
{
  *a = mix(*a, *b, 0.5f);
}
