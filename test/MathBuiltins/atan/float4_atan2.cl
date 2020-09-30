// RUN: clspv %s -o %t.spv -cl-native-math
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK: %[[A_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain
// CHECK: %[[B_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain
// CHECK: %[[C_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]] %[[B_ACCESS_CHAIN_ID]]
// CHECK: %[[LOADC_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]] %[[C_ACCESS_CHAIN_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_VECTOR_TYPE_ID]] %[[EXT_INST]] Atan2 %[[LOADB_ID]] %[[LOADC_ID]]
// CHECK: OpStore %[[A_ACCESS_CHAIN_ID]] %[[OP_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float4* b, global float4* c)
{
  *a = atan2(*b, *c);
}
