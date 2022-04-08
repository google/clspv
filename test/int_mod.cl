// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[GLSL:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[UINT0:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[UINT1:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1
// CHECK-DAG: %[[UINTM1:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 4294967295
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global int* b)
{
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]]
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]]
// CHECK: %[[ABSA_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[UINT_TYPE_ID]] %[[GLSL]] SAbs %[[LOADA_ID]]
// CHECK: %[[ABSB_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[UINT_TYPE_ID]] %[[GLSL]] SAbs %[[LOADB_ID]]
// CHECK: %[[SREM_ID:[a-zA-Z0-9_]*]] = OpUMod %[[UINT_TYPE_ID]] %[[ABSA_ID]] %[[ABSB_ID]]
// CHECK: %[[A_POS_ID:[a-zA-Z0-9_]*]] = OpSGreaterThan %[[BOOL_TYPE_ID]] %[[LOADA_ID]] %[[UINT0]]
// CHECK: %[[XOR:[a-zA-Z0-9_]*]] = OpBitwiseXor %[[UINT_TYPE_ID]] %[[SREM_ID]] %[[UINTM1]]
// CHECK: %[[ADD:[a-zA-Z0-9_]*]] = OpIAdd %[[UINT_TYPE_ID]] %[[XOR]] %[[UINT1]]
// CHECK: %[[SELECT_ID:[a-zA-Z0-9_]*]] = OpSelect %[[UINT_TYPE_ID]] %[[A_POS_ID]] %[[SREM_ID]] %[[ADD]]
// CHECK: OpStore {{.*}} %[[SELECT_ID]]
  *a %= *b;
}
