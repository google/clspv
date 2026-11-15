// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[DOUBLE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 64
// CHECK-DAG: %[[DOUBLE4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[DOUBLE_TYPE_ID]] 4
// CHECK-DAG: %[[DOUBLE3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[DOUBLE_TYPE_ID]] 3

// CHECK: %[[DOUBLE4_UNDEF_ID:[a-zA-Z0-9_]*]] = OpUndef %[[DOUBLE4_TYPE_ID]]
// CHECK-DAG: %[[DOUBLE_CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[DOUBLE_TYPE_ID]] 0
// CHECK: %[[DOUBLE_UNDEF_ID:[a-zA-Z0-9_]*]] = OpUndef %[[DOUBLE_TYPE_ID]]
// CHECK-DAG: %[[DOUBLE3_CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[DOUBLE3_TYPE_ID]] %[[DOUBLE_CONSTANT_0_ID]] %[[DOUBLE_UNDEF_ID]] %[[DOUBLE_UNDEF_ID]]
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpLoad %[[DOUBLE4_TYPE_ID]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[DOUBLE4_TYPE_ID]]
// CHECK: %[[SHUFFLEA_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[DOUBLE3_TYPE_ID]] %[[LOADA_ID]] %[[DOUBLE4_UNDEF_ID]] 0 1 2
// CHECK: %[[SHUFFLEB_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[DOUBLE3_TYPE_ID]] %[[LOADB_ID]] %[[DOUBLE4_UNDEF_ID]] 0 1 2
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[DOUBLE3_TYPE_ID]] %[[EXT_INST]] Cross %[[SHUFFLEA_ID]] %[[SHUFFLEB_ID]]
// CHECK: %[[SHUFFLEOP_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[DOUBLE4_TYPE_ID]] %[[OP_ID]] %[[DOUBLE3_CONSTANT_0_ID]] 0 1 2 3
// CHECK: OpStore {{.*}} %[[SHUFFLEOP_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global double4* a, global double4* b)
{
  *a = cross(*a, *b);
}
