// RUN: clspv %s -S -o %t.spvasm -no-inline-single
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 21
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1
// CHECK: OpDecorate %[[UINT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 4
// CHECK: OpMemberDecorate %[[UINT_ARG_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[UINT_ARG_STRUCT_TYPE_ID]] Block
// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_TYPE_ID]]
// CHECK-DAG: %[[UINT_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[UINT_TYPE_ID]]
// CHECK-DAG: %[[UINT_ARG_STRUCT_TYPE_ID]] = OpTypeStruct %[[UINT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[UINT_ARG_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_ARG_STRUCT_TYPE_ID]]
// CHECK-DAG: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK-DAG: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK-DAG: %[[REFERENCED_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[UINT_TYPE_ID]] %[[UINT_TYPE_ID]]


// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 42

// CHECK: %[[ARG0_ID]] = OpVariable %[[UINT_ARG_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[REFERENCED_ID:[a-zA-Z0-9_]*]] = OpFunction %[[UINT_TYPE_ID]] Const %[[REFERENCED_TYPE_ID]]
// CHECK: %[[REFERENCED_A_ID:[a-zA-Z0-9_]*]] = OpFunctionParameter %[[UINT_TYPE_ID]]
// CHECK: %[[REFERENCED_LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[REFERENCED_OP_ID:[a-zA-Z0-9_]*]] = OpIAdd %[[UINT_TYPE_ID]] %[[REFERENCED_A_ID]] %[[CONSTANT_42_ID]]
// CHECK: OpReturnValue %[[REFERENCED_OP_ID]]
// CHECK: OpFunctionEnd

int referenced(int a) {
  return a + 42;
}

// CHECK-NOT: OpFunction %[[UINT_TYPE_ID]] Const %[[REFERENCED_TYPE_ID]]

int unreferenced(int a) {
  return a + 13;
}

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[LOADA_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[LOADA_ACCESS_CHAIN_ID]]
// CHECK: %[[CALL_ID:[a-zA-Z0-9_]*]] = OpFunctionCall %[[UINT_TYPE_ID]] %[[REFERENCED_ID]] %[[LOADA_ID]]
// CHECK: OpStore %[[LOADA_ACCESS_CHAIN_ID]] %[[CALL_ID]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a) {
  *a = referenced(*a);
}
