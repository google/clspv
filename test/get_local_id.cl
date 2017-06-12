// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 34
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo" %[[BUILTIN_ID:[a-zA-Z0-9_]*]]
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1
// CHECK: OpDecorate %[[UINT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 4
// CHECK: OpMemberDecorate %[[UINT_ARG0_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[UINT_ARG0_STRUCT_TYPE_ID]] BufferBlock
// CHECK: OpMemberDecorate %[[UINT_ARG1_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[UINT_ARG1_STRUCT_TYPE_ID]] BufferBlock
// CHECK: OpDecorate %[[BUILTIN_ID]] BuiltIn LocalInvocationId
// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0
// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG1_ID]] Binding 1
// CHECK: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK: %[[UINT_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_TYPE_ID]]
// CHECK: %[[UINT_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[UINT_TYPE_ID]]
// CHECK: %[[UINT_ARG0_STRUCT_TYPE_ID]] = OpTypeStruct %[[UINT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK: %[[UINT_ARG0_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_ARG0_STRUCT_TYPE_ID]]
// CHECK: %[[UINT_ARG1_STRUCT_TYPE_ID]] = OpTypeStruct %[[UINT_TYPE_ID]]
// CHECK: %[[UINT_ARG1_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_ARG1_STRUCT_TYPE_ID]]
// CHECK: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK: %[[GET_LOCAL_ID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[UINT_TYPE_ID]] %[[UINT_TYPE_ID]]
// CHECK: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK: %[[UINT3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 3
// CHECK: %[[UINT3_INPUT_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer Input %[[UINT3_TYPE_ID]]
// CHECK: %[[UINT_INPUT_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer Input %[[UINT_TYPE_ID]]
// CHECK: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: %[[CONSTANT_3_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 3
// CHECK: %[[BUILTIN_ID]] = OpVariable %[[UINT3_INPUT_POINTER_TYPE_ID]] Input
// CHECK: %[[ARG0_ID]] = OpVariable %[[UINT_ARG0_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG1_ID]] = OpVariable %[[UINT_ARG1_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL1_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[ACCESS_CHAIN1_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[ARG1_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOAD1_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[ACCESS_CHAIN1_ID]]
// CHECK: %[[RESULT_ID:[a-zA-Z0-9_]*]] = OpFunctionCall %[[UINT_TYPE_ID]] %[[GET_LOCAL_ID_ID:[a-zA-Z0-9_]*]] %[[LOAD1_ID]]
// CHECK: %[[ACCESS_CHAIN2_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[RESULT_ID]]
// CHECK: OpStore %[[ACCESS_CHAIN2_ID]] %[[CONSTANT_0_ID]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, uint b)
{
  a[get_local_id(b)] = get_local_id(3);
}

// CHECK: %[[GET_LOCAL_ID_ID]] = OpFunction %[[UINT_TYPE_ID]] Const %[[GET_LOCAL_ID_TYPE_ID]]
// CHECK: %[[FUNC_PARAM_ID:[a-zA-Z0-9_]*]] = OpFunctionParameter %[[UINT_TYPE_ID]]
// CHECK: %[[LABEL2_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[COND_ID:[a-zA-Z0-9_]*]] = OpULessThan %[[BOOL_TYPE_ID]] %[[FUNC_PARAM_ID]] %[[CONSTANT_3_ID]]
// CHECK: %[[SELECT1_ID:[a-zA-Z0-9_]*]] = OpSelect %[[UINT_TYPE_ID]] %[[COND_ID]] %[[FUNC_PARAM_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[ACCESS_CHAIN3_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_INPUT_POINTER_TYPE_ID]] %[[BUILTIN_ID]] %[[SELECT1_ID]]
// CHECK: %[[LOAD2_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[ACCESS_CHAIN3_ID]]
// CHECK: %[[SELECT2_ID:[a-zA-Z0-9_]*]] = OpSelect %[[UINT_TYPE_ID]] %[[COND_ID]] %[[LOAD2_ID]] %[[CONSTANT_0_ID]]
// CHECK: OpReturnValue %[[SELECT2_ID]]
// CHECK: OpFunctionEnd
