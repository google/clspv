// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 1
// CHECK-DAG: %[[CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 42
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a)
{
// CHECK: %[[LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]]
  const float aLoad = *a;

// CHECK: %[[CMP_ID:[a-zA-Z0-9_]*]] = OpFOrdGreaterThanEqual %[[BOOL_TYPE_ID]] %[[LOAD_ID]] %[[CONSTANT_42_ID]]
  const bool c = (aLoad >= 42.0f);

// CHECK: %[[CAS_ID:[a-zA-Z0-9_]*]] = OpSelect %[[FLOAT_TYPE_ID]] %[[CMP_ID]] %[[CONSTANT_1_ID]] %[[CONSTANT_0_ID]]
  const float cAs = c;

// CHECK: OpStore {{.*}} %[[CAS_ID]]
  *a = cAs;

}
