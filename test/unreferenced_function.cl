// RUN: clspv %target %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK-DAG: %[[REFERENCED_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[UINT_TYPE_ID]] %[[UINT_TYPE_ID]]


// CHECK-DAG: %[[CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 42
// CHECK: %[[REFERENCED_ID:[a-zA-Z0-9_]*]] = OpFunction %[[UINT_TYPE_ID]] {{.*}} %[[REFERENCED_TYPE_ID]]
// CHECK: %[[REFERENCED_A_ID:[a-zA-Z0-9_]*]] = OpFunctionParameter %[[UINT_TYPE_ID]]
// CHECK: %[[REFERENCED_LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[REFERENCED_OP_ID:[a-zA-Z0-9_]*]] = OpIAdd %[[UINT_TYPE_ID]] %[[REFERENCED_A_ID]] %[[CONSTANT_42_ID]]
// CHECK: OpReturnValue %[[REFERENCED_OP_ID]]
// CHECK: OpFunctionEnd

__attribute__((noinline))
int referenced(int a) {
  return a + 42;
}

// CHECK-NOT: OpFunction %[[UINT_TYPE_ID]] Const %[[REFERENCED_TYPE_ID]]

int unreferenced(int a) {
  return a + 13;
}

// CHECK: %[[FOO_ID]] = OpFunction
// CHECK: %[[CALL_ID:[a-zA-Z0-9_]*]] = OpFunctionCall %[[UINT_TYPE_ID]] %[[REFERENCED_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a) {
  *a = referenced(*a);
}
