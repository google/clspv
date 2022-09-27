// We have -O0 here because the compiler will optimize away the unused
// local uint b[5] otherwise.
// RUN: clspv %target -O0 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[CONSTANT_5_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 5
// CHECK-DAG: %[[UINT_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeArray %[[UINT_TYPE_ID]] %[[CONSTANT_5_ID]]
// CHECK-DAG: %[[UINT_ARRAY_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer Workgroup %[[UINT_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: %[[LOCAL_VAR_ID:[a-zA-Z0-9_]*]] = OpVariable %[[UINT_ARRAY_POINTER_TYPE_ID]] Workgroup

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint * a) {
  local uint b[5];
  *a = 5;
}
