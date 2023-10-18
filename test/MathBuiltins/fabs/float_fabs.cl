// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT_MAX_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 2147483647
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]]
// CHECK: %[[BITCAST_ID:[a-zA-Z0-9_]*]] = OpBitcast %[[UINT_TYPE_ID]] %[[LOADB_ID]]
// CHECK: %[[AND_ID:[a-zA-Z0-9_]*]] = OpBitwiseAnd %[[UINT_TYPE_ID]] %[[BITCAST_ID]] %[[UINT_MAX_ID]]
// CHECK: %[[BITCAST_ID:[a-zA-Z0-9_]*]] = OpBitcast %[[FLOAT_TYPE_ID]] %[[AND_ID]]
// CHECK: OpStore {{.*}} %[[BITCAST_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global float* b)
{
  *a = fabs(*b);
}
