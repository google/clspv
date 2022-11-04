// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[VEC_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[TYPE_ID]] 2
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[VEC_BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[BOOL_TYPE_ID]] 2
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float2* a, global float2* b)
{
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[VEC_TYPE_ID]]
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpLoad %[[VEC_TYPE_ID]]
// CHECK: %[[ABS_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[VEC_TYPE_ID]] {{.*}} FAbs %[[LOADB_ID]]
// CHECK: %[[CMP0_ID:[a-zA-Z0-9_]*]] = OpFOrdGreaterThan %[[VEC_BOOL_TYPE_ID]] %[[ABS_ID]]
// CHECK: %[[CMP1_ID:[a-zA-Z0-9_]*]] = OpFOrdLessThan %[[VEC_BOOL_TYPE_ID]] %[[ABS_ID]]
// CHECK: %[[SELECT0_ID:[a-zA-Z0-9_]*]] = OpSelect %[[VEC_TYPE_ID]] %[[CMP0_ID]]
// CHECK: %[[SELECT1_ID:[a-zA-Z0-9_]*]] = OpSelect %[[VEC_TYPE_ID]] %[[CMP1_ID]] {{.*}} %[[SELECT0_ID]]
// CHECK: %[[MUL_ID:[a-zA-Z0-9_]*]] = OpFMul %[[VEC_TYPE_ID]] %[[LOADB_ID]] %[[SELECT1_ID]]
// CHECK: %[[DIV_ID:[a-zA-Z0-9_]*]] = OpFDiv %[[VEC_TYPE_ID]] %[[LOADA_ID]] %[[MUL_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpFMul %[[VEC_TYPE_ID]] %[[DIV_ID]] %[[SELECT1_ID]]
// CHECK: OpStore {{.*}} %[[OP_ID]]
  *a /= *b;
}
