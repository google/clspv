// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 36
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo" %[[BUILTIN_ID:[a-zA-Z0-9_]*]]
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 4 1 1
// CHECK: OpDecorate %[[UINT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 4
// CHECK: OpMemberDecorate %[[UINT_ARG_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[UINT_ARG_STRUCT_TYPE_ID]] Block
// CHECK: OpDecorate %[[BUILTIN_ID]] BuiltIn LocalInvocationId
// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0

// CHECK-NOT: OpDecorate %{{[a-zA-Z0-9_]+}} ArrayStride

// CHECK: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK: %[[UINT_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_TYPE_ID]]
// CHECK: %[[UINT_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[UINT_TYPE_ID]]
// CHECK: %[[UINT_ARG_STRUCT_TYPE_ID]] = OpTypeStruct %[[UINT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK: %[[UINT_ARG_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_ARG_STRUCT_TYPE_ID]]

// CHECK: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]

// CHECK: %[[CONSTANT_4_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 4
// CHECK: %[[B_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeArray %[[UINT_TYPE_ID]] %[[CONSTANT_4_ID]]
// CHECK: %[[B_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer Private %[[B_TYPE_ID]]
// CHECK: %[[UINT_PRIVATE_POINTER_TYPE_ID:[a-zA-Z0-9_]+]] = OpTypePointer Private %[[UINT_TYPE_ID]]

// CHECK: %[[BAR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[UINT_TYPE_ID]] %[[UINT_PRIVATE_POINTER_TYPE_ID]]

// CHECK: %[[UINT3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 3
// CHECK: %[[UINT3_INPUT_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer Input %[[UINT3_TYPE_ID]]
// CHECK: %[[UINT_INPUT_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer Input %[[UINT_TYPE_ID]]

// CHECK: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: %[[CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 42
// CHECK: %[[CONSTANT_13_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 13
// CHECK: %[[CONSTANT_5_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 5
// CHECK: %[[CONSTANT_B_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[B_TYPE_ID]] %[[CONSTANT_42_ID]] %[[CONSTANT_13_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_5_ID]]

// CHECK: %[[BUILTIN_ID]] = OpVariable %[[UINT3_INPUT_POINTER_TYPE_ID]] Input
// CHECK: %[[B_ID:[a-zA-Z0-9_]*]] = OpVariable %[[B_POINTER_TYPE_ID]] Private %[[CONSTANT_B_ID]]

constant uint b[4] = {42, 13, 0, 5};

// CHECK: %[[ARG0_ID]] = OpVariable %[[UINT_ARG_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[BAR_ID:[a-zA-Z0-9_]*]] = OpFunction %[[UINT_TYPE_ID]] Pure %[[BAR_TYPE_ID]]
// CHECK: %[[BAR_ARG0_ID:[a-zA-Z0-9_]*]] = OpFunctionParameter %[[UINT_PRIVATE_POINTER_TYPE_ID]]
// CHECK: %[[BAR_LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel

// CHECK: %[[BUILTIN_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_INPUT_POINTER_TYPE_ID]] %[[BUILTIN_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOCAL_X_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[BUILTIN_ACCESS_CHAIN_ID]]

// TODO(dneto): OpPtrAccessChain on pointer to Private is not alloweed by SPV_KHR_variable_pointers
// CHECK: %[[BAR_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpPtrAccessChain %[[UINT_PRIVATE_POINTER_TYPE_ID]] %[[BAR_ARG0_ID]] %[[LOCAL_X_ID]]
// CHECK: %[[BAR_RETURN_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[BAR_ACCESS_CHAIN_ID]]
// CHECK: OpReturnValue %[[BAR_RETURN_ID]]
// CHECK: OpFunctionEnd

uint bar(constant uint* a)
{
  return a[get_local_id(0)];
}

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[FOO_LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[A_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[B_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_PRIVATE_POINTER_TYPE_ID]] %[[B_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[CALL_ID:[a-zA-Z0-9_]*]] = OpFunctionCall %[[UINT_TYPE_ID]] %[[BAR_ID]] %[[B_ACCESS_CHAIN_ID]]
// CHECK: OpStore %[[A_ACCESS_CHAIN_ID]] %[[CALL_ID]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(4, 1, 1))) foo(global uint* a)
{
  *a = bar(b);
}
