// RUN: clspv %target %s --long-vector -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[INT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32
// CHECK-DAG: %[[INT8:[a-zA-Z0-9_]*]] = OpConstant %[[INT_TYPE_ID]] 8
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeArray %[[FLOAT_TYPE_ID]] %[[INT8]]
// CHECK-COUNT-8: OpLoad
// CHECK: OpCompositeConstruct %[[FLOAT_ARRAY_TYPE_ID]]
// CHECK-NOT: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_TYPE_ID]] %{{.*}} Cos
// CHECK-DAG: OpFunctionCall %[[FLOAT_ARRAY_TYPE_ID]]
// CHECK: OpCompositeExtract %[[FLOAT_TYPE_ID]]
// CHECK: OpStore
// CHECK: OpCompositeExtract %[[FLOAT_TYPE_ID]]
// CHECK: OpStore
// CHECK: OpCompositeExtract %[[FLOAT_TYPE_ID]]
// CHECK: OpStore
// CHECK: OpCompositeExtract %[[FLOAT_TYPE_ID]]
// CHECK: OpStore
// CHECK: OpCompositeExtract %[[FLOAT_TYPE_ID]]
// CHECK: OpStore
// CHECK: OpCompositeExtract %[[FLOAT_TYPE_ID]]
// CHECK: OpStore
// CHECK: OpCompositeExtract %[[FLOAT_TYPE_ID]]
// CHECK: OpStore
// CHECK: OpCompositeExtract %[[FLOAT_TYPE_ID]]
// CHECK: OpStore

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float8* a, global float8* b)
{
  *a = cos(*b);
}
