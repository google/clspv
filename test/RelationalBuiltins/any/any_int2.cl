// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 2
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[BOOL2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[BOOL_TYPE_ID]] 2
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1
// CHECK-DAG: %[[UINT2_CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstantNull %[[UINT2_TYPE_ID]]
// CHECK: %[[B_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT2_TYPE_ID]]
// CHECK: %[[CMP_ID:[a-zA-Z0-9_]*]] = OpSLessThan %[[BOOL2_TYPE_ID]] %[[B_LOAD_ID]] %[[UINT2_CONSTANT_0_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpAny %[[BOOL_TYPE_ID]] %[[CMP_ID]]
// CHECK: %[[CAS_ID:[a-zA-Z0-9_]*]] = OpSelect %[[UINT_TYPE_ID]] %[[OP_ID]] %[[CONSTANT_1_ID]] %[[CONSTANT_0_ID]]
// CHECK: OpStore {{.*}} %[[CAS_ID]]
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global int2* b)
{
  *a = any(b[0]);
}
