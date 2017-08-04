// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 32
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1
// CHECK: OpDecorate %[[ARG0_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 4
// CHECK: OpMemberDecorate %[[ARG0_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG0_STRUCT_TYPE_ID]] Block
// CHECK: OpMemberDecorate %[[THING_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG1_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 512
// CHECK: OpMemberDecorate %[[ARG1_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG1_STRUCT_TYPE_ID]] Block
// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0
// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG1_ID]] Binding 1
// CHECK-NEXT: OpDecorate %[[FLOAT_POINTER_TYPE_ID:[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK: %[[FLOAT_POINTER_TYPE_ID]] = OpTypePointer StorageBuffer %[[FLOAT_TYPE_ID]]
// CHECK: %[[ARG0_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[FLOAT_TYPE_ID]]
// CHECK: %[[ARG0_STRUCT_TYPE_ID]] = OpTypeStruct %[[ARG0_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK: %[[ARG0_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG0_STRUCT_TYPE_ID]]
// CHECK: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK: %[[CONSTANT_128_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 128
// CHECK: %[[CONSTANT_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeArray %[[FLOAT_TYPE_ID]] %[[CONSTANT_128_ID]]
// CHECK: %[[THING_TYPE_ID]] = OpTypeStruct %[[CONSTANT_ARRAY_TYPE_ID]]
// CHECK: %[[THING_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[THING_TYPE_ID]]
// CHECK: %[[ARG1_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[THING_TYPE_ID]]
// CHECK: %[[ARG1_STRUCT_TYPE_ID]] = OpTypeStruct %[[ARG1_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK: %[[ARG1_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG1_STRUCT_TYPE_ID]]

struct Thing
{
  float a[128];
};

// CHECK: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK: %[[BAR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[FLOAT_TYPE_ID]] %[[THING_GLOBAL_POINTER_TYPE_ID]]

// CHECK: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1
// CHECK: %[[CONSTANT_5_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 5

// CHECK: %[[ARG0_ID]] = OpVariable %[[ARG0_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG1_ID]] = OpVariable %[[ARG1_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[BAR_ID:[a-zA-Z0-9_]*]] = OpFunction %[[FLOAT_TYPE_ID]] Pure %[[BAR_TYPE_ID]]
// CHECK: %[[BAR_ARG0_ID:[a-zA-Z0-9_]*]] = OpFunctionParameter %[[THING_GLOBAL_POINTER_TYPE_ID]]
// CHECK: %[[BAR_LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[BAR_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpPtrAccessChain %[[FLOAT_POINTER_TYPE_ID]] %[[BAR_ARG0_ID]] %[[CONSTANT_1_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_5_ID]]
// CHECK: %[[BAR_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]] %[[BAR_ACCESS_CHAIN_ID]]
// CHECK: OpReturnValue %[[BAR_LOAD_ID]]
// CHECK: OpFunctionEnd


float bar(global struct Thing* a)
{
  return a[1].a[5];
}

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[A_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[B_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[THING_GLOBAL_POINTER_TYPE_ID]] %[[ARG1_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[CALL_ID:[a-zA-Z0-9_]*]] = OpFunctionCall %[[FLOAT_TYPE_ID]] %[[BAR_ID]] %[[B_ACCESS_CHAIN_ID]]
// CHECK: OpStore %[[A_ACCESS_CHAIN_ID]] %[[CALL_ID]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global struct Thing* b)
{
  *a = bar(b);
}
