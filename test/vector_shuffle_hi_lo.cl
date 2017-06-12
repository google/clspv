// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0 
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 27    
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute  %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1 
// CHECK: OpMemberDecorate %[[ARG0_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG0_STRUCT_TYPE_ID]] BufferBlock
// CHECK: OpDecorate %[[FLOAT_2_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 8
// CHECK: OpMemberDecorate %[[ARG12_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG12_STRUCT_TYPE_ID]] BufferBlock
// CHECK: OpDecorate %[[ARG_0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG_0_ID]] Binding 0
// CHECK: OpDecorate %[[ARG_1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG_1_ID]] Binding 1
// CHECK: OpDecorate %[[ARG_2_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG_2_ID]] Binding 2
// CHECK: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK: %[[FLOAT_4_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK: %[[ARG0_STRUCT_TYPE_ID]] = OpTypeStruct %[[FLOAT_4_VECTOR_TYPE_ID]]
// CHECK: %[[ARG0_STRUCT_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG0_STRUCT_TYPE_ID]]
// CHECK: %[[FLOAT_4_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_4_VECTOR_TYPE_ID]]
// CHECK: %[[FLOAT_2_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2
// CHECK: %[[FLOAT_2_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_2_VECTOR_TYPE_ID]]
// CHECK: %[[FLOAT_2_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[FLOAT_2_VECTOR_TYPE_ID]]
// CHECK: %[[ARG12_STRUCT_TYPE_ID]] = OpTypeStruct %[[FLOAT_2_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK: %[[ARG12_STRUCT_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG12_STRUCT_TYPE_ID]]
// CHECK: %[[INT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]] 
// CHECK: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[INT_TYPE_ID]] 0
// CHECK: %[[UNDEF_ID:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT_4_VECTOR_TYPE_ID]]
// CHECK: %[[ARG_0_ID]] = OpVariable %[[ARG0_STRUCT_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG_1_ID]] = OpVariable %[[ARG12_STRUCT_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG_2_ID]] = OpVariable %[[ARG12_STRUCT_POINTER_TYPE_ID]] StorageBuffer


// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]] 
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[ARG0_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_4_POINTER_TYPE_ID]] %[[ARG_0_ID]] %[[CONSTANT_0_ID]] 
// CHECK: %[[LOAD_ARG0_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_4_VECTOR_TYPE_ID]] %[[ARG0_ACCESS_CHAIN_ID]] 
// CHECK: %[[ARG1_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_2_POINTER_TYPE_ID]] %[[ARG_1_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]] 
// CHECK: %[[ARG2_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_2_POINTER_TYPE_ID]] %[[ARG_2_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]] 
// CHECK: %[[VECTOR_SHUFFLE_HI_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT_2_VECTOR_TYPE_ID]] %[[LOAD_ARG0_ID]] %[[UNDEF_ID]] 2 3 
// CHECK:         OpStore  %[[ARG1_ACCESS_CHAIN_ID]] %[[VECTOR_SHUFFLE_HI_ID]] 
// CHECK: %[[VECTOR_SHUFFLE_LO_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT_2_VECTOR_TYPE_ID]] %[[LOAD_ARG0_ID]] %[[UNDEF_ID]] 0 1 
// CHECK: OpStore  %[[ARG2_ACCESS_CHAIN_ID]] %[[VECTOR_SHUFFLE_LO_ID]] 
// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(float4 a, global float2 *b, global float2 *c)
{
  (*b) = a.hi;
  (*c) = a.lo;
}
