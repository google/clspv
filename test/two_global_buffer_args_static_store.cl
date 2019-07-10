// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] Binding 0
// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] Binding 1
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_TYPE_ID]]
// CHECK-DAG: %[[UINT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeRuntimeArray %[[UINT_TYPE_ID]]
// CHECK-DAG: %[[UINT_ARG0_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeStruct %[[UINT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[UINT_ARG0_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_ARG0_STRUCT_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeRuntimeArray %[[FLOAT_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_ARG1_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeStruct %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_ARG1_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_ARG1_STRUCT_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[UINT_CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 42
// CHECK-DAG: %[[FLOAT_CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 42
// CHECK: %[[ARG0_ID]] = OpVariable %[[UINT_ARG0_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG1_ID]] = OpVariable %[[FLOAT_ARG1_POINTER_TYPE_ID]] StorageBuffer
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, global float* b)
{
// CHECK: %[[ACCESS_CHAIN1_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[ACCESS_CHAIN2_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_GLOBAL_POINTER_TYPE_ID]] %[[ARG1_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: OpStore %[[ACCESS_CHAIN1_ID]] %[[UINT_CONSTANT_42_ID]]
  *a = 42;
// CHECK: OpStore %[[ACCESS_CHAIN2_ID]] %[[FLOAT_CONSTANT_42_ID]]
  *b = 42.0f;
}
