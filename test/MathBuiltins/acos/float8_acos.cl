// RUN: clspv %target %s -o %t.spv --long-vector
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeArray %[[FLOAT_TYPE_ID]]
// CHECK: %[[BUILTIN_ID:[a-zA-Z0-9_]*]] = OpFunction %[[ARRAY_TYPE_ID]]
// CHECK: OpLabel
// CHECK: OpFunction
// CHECK-NOT: OpExtInst {{.*}} Acos
// CHECK: OpFunctionCall %[[ARRAY_TYPE_ID]] %[[BUILTIN_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float8* a, constant float8* b)
{
  *a = acos(*b);
}
