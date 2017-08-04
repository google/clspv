// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0 
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 23    
// CHECK: ; Schema: 0
// CHECK:         OpCapability Shader
// CHECK:         OpMemoryModel Logical GLSL450
// CHECK:         OpEntryPoint GLCompute  %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK:         OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1 
// CHECK:         OpMemberDecorate %[[FLOAT_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK:         OpDecorate %[[FLOAT_STRUCT_TYPE_ID]] Block
// CHECK:         OpDecorate %[[FLOAT_VECTOR_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 16
// CHECK:         OpMemberDecorate %[[FLOAT_VECTOR_DYNAMIC_ARRAY_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK:         OpDecorate %[[FLOAT_VECTOR_DYNAMIC_ARRAY_STRUCT_TYPE_ID]] Block
// CHECK:         OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK:         OpDecorate %[[ARG0_ID]] Binding 0
// CHECK:         OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK:         OpDecorate %[[ARG1_ID]] Binding 1
// CHECK: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK: %[[FLOAT_STRUCT_TYPE_ID]] = OpTypeStruct %[[FLOAT_TYPE_ID]]
// CHECK: %[[FLOAT_STRUCT_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_STRUCT_TYPE_ID]]
// CHECK: %[[FLOAT_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_TYPE_ID]]
// CHECK: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK: %[[FLOAT_VECTOR_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: %[[FLOAT_VECTOR_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: %[[FLOAT_VECTOR_DYNAMIC_ARRAY_STRUCT_TYPE_ID]] = OpTypeStruct %[[FLOAT_VECTOR_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK: %[[FLOAT_VECTOR_DYNAMIC_ARRAY_STRUCT_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_VECTOR_DYNAMIC_ARRAY_STRUCT_TYPE_ID]]
// CHECK: %[[INT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]] 
// CHECK: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[INT_TYPE_ID]] 0
// CHECK: %[[ARG0_ID]] = OpVariable %[[FLOAT_STRUCT_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG1_ID]] = OpVariable %[[FLOAT_VECTOR_DYNAMIC_ARRAY_STRUCT_POINTER_TYPE_ID]] StorageBuffer


// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]] 
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[ARG0_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] 
// CHECK: %[[LOAD_ARG0_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]] %[[ARG0_ACCESS_CHAIN_ID]] 
// CHECK: %[[ARG1_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_VECTOR_POINTER_TYPE_ID]] %[[ARG1_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]] 
// CHECK: %[[LOAD_ARG1_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]] %[[ARG1_ACCESS_CHAIN_ID]] 
// CHECK: %[[COMPOSITE_INSERT_ID:[a-zA-Z0-9_]*]] = OpCompositeInsert %[[FLOAT_VECTOR_TYPE_ID]] %[[LOAD_ARG0_ID]] %[[LOAD_ARG1_ID]] 1
// CHECK:         OpStore  %[[ARG1_ACCESS_CHAIN_ID]] %[[COMPOSITE_INSERT_ID]] 
// CHECK:         OpReturn
// CHECK:         OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(float a, global float4 *b) 
{
  (*b).y = a;
}
