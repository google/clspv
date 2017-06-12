// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 19
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability Int16
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1
// CHECK: OpDecorate %[[USHORT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 2
// CHECK: OpMemberDecorate %[[USHORT_ARG_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[USHORT_ARG_STRUCT_TYPE_ID]] BufferBlock
// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0
// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG1_ID]] Binding 1
// CHECK: %[[USHORT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 16 0
// CHECK: %[[USHORT_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[USHORT_TYPE_ID]]
// CHECK: %[[USHORT_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[USHORT_TYPE_ID]]
// CHECK: %[[USHORT_ARG_STRUCT_TYPE_ID]] = OpTypeStruct %[[USHORT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK: %[[USHORT_ARG_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[USHORT_ARG_STRUCT_TYPE_ID]]
// CHECK: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: %[[ARG0_ID]] = OpVariable %[[USHORT_ARG_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG1_ID]] = OpVariable %[[USHORT_ARG_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global short* a, global short* b)
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
{
// CHECK: %[[LOADA_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[USHORT_GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOADB_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[USHORT_GLOBAL_POINTER_TYPE_ID]] %[[ARG1_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[USHORT_TYPE_ID]] %[[LOADB_ACCESS_CHAIN_ID]]
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpLoad %[[USHORT_TYPE_ID]] %[[LOADA_ACCESS_CHAIN_ID]]
// CHECK: %[[IADD_ID:[a-zA-Z0-9_]*]] = OpIAdd %[[USHORT_TYPE_ID]] %[[LOADA_ID]] %[[LOADB_ID]]
// CHECK: OpStore %[[LOADA_ACCESS_CHAIN_ID]] %[[IADD_ID]]
  *a += *b;
// CHECK: OpReturn
}
// CHECK: OpFunctionEnd
