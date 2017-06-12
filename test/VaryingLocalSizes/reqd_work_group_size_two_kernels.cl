// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 46
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpEntryPoint GLCompute %[[BAR_ID:[a-zA-Z0-9_]*]] "bar"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 42 13 5
// CHECK: OpExecutionMode %[[BAR_ID]] LocalSize 42 13 5
// CHECK: OpDecorate %[[UINT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 4
// CHECK: OpMemberDecorate %[[UINT_ARG0_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[UINT_ARG0_STRUCT_TYPE_ID]] BufferBlock
// CHECK: OpDecorate %[[FOO_ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[FOO_ARG0_ID]] Binding 0
// CHECK: OpDecorate %[[BAR_ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 1
// CHECK: OpDecorate %[[BAR_ARG0_ID]] Binding 0
// CHECK: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK: %[[UINT_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_TYPE_ID]]
// CHECK: %[[UINT_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[UINT_TYPE_ID]]
// CHECK: %[[UINT_ARG0_STRUCT_TYPE_ID]] = OpTypeStruct %[[UINT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK: %[[UINT_ARG0_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_ARG0_STRUCT_TYPE_ID]]
// CHECK: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK: %[[UINT3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 3
// CHECK: %[[UINT3_PRIVATE_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer Private %[[UINT3_TYPE_ID]]
// CHECK: %[[UINT_PRIVATE_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer Private %[[UINT_TYPE_ID]]
// CHECK: %[[CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 42
// CHECK: %[[CONSTANT_13_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 13
// CHECK: %[[CONSTANT_5_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 5
// CHECK: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1
// CHECK: %[[CONSTANT_2_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 2
// CHECK: %[[CONSTANT_3_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 3
// CHECK: %[[BUILTIN_FOR_FOO_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[UINT3_TYPE_ID]] %[[CONSTANT_42_ID]] %[[CONSTANT_13_ID]] %[[CONSTANT_5_ID]]
// CHECK: %[[BUILTIN_VAR_FOR_FOO_ID:[a-zA-Z0-9_]*]] = OpVariable %[[UINT3_PRIVATE_POINTER_TYPE_ID]] Private %[[BUILTIN_FOR_FOO_ID]]
// CHECK: %[[FOO_ARG0_ID]] = OpVariable %[[UINT_ARG0_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[BAR_ARG0_ID]] = OpVariable %[[UINT_ARG0_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL1_ID:[a-zA-Z0-9_]*]] = OpLabel

// CHECK: %[[ACCESS_CHAIN0_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[FOO_ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOAD_ACCESS_CHAIN0_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_PRIVATE_POINTER_TYPE_ID]] %[[BUILTIN_VAR_FOR_FOO_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOAD0_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[LOAD_ACCESS_CHAIN0_ID]]
// CHECK: OpStore %[[ACCESS_CHAIN0_ID]] %[[LOAD0_ID]]

// CHECK: %[[LOAD_ACCESS_CHAIN1_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_PRIVATE_POINTER_TYPE_ID]] %[[BUILTIN_VAR_FOR_FOO_ID]] %[[CONSTANT_1_ID]]
// CHECK: %[[LOAD1_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[LOAD_ACCESS_CHAIN1_ID]]
// CHECK: %[[ACCESS_CHAIN1_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[FOO_ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_1_ID]]
// CHECK: OpStore %[[ACCESS_CHAIN1_ID]] %[[LOAD1_ID]]

// CHECK: %[[LOAD_ACCESS_CHAIN2_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_PRIVATE_POINTER_TYPE_ID]] %[[BUILTIN_VAR_FOR_FOO_ID]] %[[CONSTANT_2_ID]]
// CHECK: %[[LOAD2_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[LOAD_ACCESS_CHAIN2_ID]]
// CHECK: %[[ACCESS_CHAIN2_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[FOO_ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_2_ID]]
// CHECK: OpStore %[[ACCESS_CHAIN2_ID]] %[[LOAD2_ID]]

// CHECK: %[[ACCESS_CHAIN3_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[FOO_ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_3_ID]]
// CHECK: OpStore %[[ACCESS_CHAIN3_ID]] %[[CONSTANT_1_ID]]

// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(42, 13, 5))) foo(global uint* a)
{
  a[0] = get_local_size(0);
  a[1] = get_local_size(1);
  a[2] = get_local_size(2);
  a[3] = get_local_size(3);
}

// CHECK: %[[BAR_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL1_ID:[a-zA-Z0-9_]*]] = OpLabel

// CHECK: %[[BAR_ACCESS_CHAIN0_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[BAR_ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[BAR_LOAD_ACCESS_CHAIN0_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_PRIVATE_POINTER_TYPE_ID]] %[[BUILTIN_VAR_FOR_FOO_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[BAR_LOAD0_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[BAR_LOAD_ACCESS_CHAIN0_ID]]
// CHECK: OpStore %[[BAR_ACCESS_CHAIN0_ID]] %[[BAR_LOAD0_ID]]

// CHECK: %[[BAR_LOAD_ACCESS_CHAIN1_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_PRIVATE_POINTER_TYPE_ID]] %[[BUILTIN_VAR_FOR_FOO_ID]] %[[CONSTANT_1_ID]]
// CHECK: %[[BAR_LOAD1_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[BAR_LOAD_ACCESS_CHAIN1_ID]]
// CHECK: %[[BAR_ACCESS_CHAIN1_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[BAR_ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_1_ID]]
// CHECK: OpStore %[[BAR_ACCESS_CHAIN1_ID]] %[[BAR_LOAD1_ID]]

// CHECK: %[[BAR_LOAD_ACCESS_CHAIN2_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_PRIVATE_POINTER_TYPE_ID]] %[[BUILTIN_VAR_FOR_FOO_ID]] %[[CONSTANT_2_ID]]
// CHECK: %[[BAR_LOAD2_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[BAR_LOAD_ACCESS_CHAIN2_ID]]
// CHECK: %[[BAR_ACCESS_CHAIN2_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[BAR_ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_2_ID]]
// CHECK: OpStore %[[BAR_ACCESS_CHAIN2_ID]] %[[BAR_LOAD2_ID]]

// CHECK: %[[BAR_ACCESS_CHAIN3_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[BAR_ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_3_ID]]
// CHECK: OpStore %[[BAR_ACCESS_CHAIN3_ID]] %[[CONSTANT_1_ID]]

// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(42, 13, 5))) bar(global uint* a)
{
  a[0] = get_local_size(0);
  a[1] = get_local_size(1);
  a[2] = get_local_size(2);
  a[3] = get_local_size(3);
}
