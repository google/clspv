// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 20
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1
// CHECK: OpDecorate %[[DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 16
// CHECK: OpMemberDecorate %[[ARG_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG_STRUCT_TYPE_ID]] Block
// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0
// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG1_ID]] Binding 1
// CHECK-DAG: %[[TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[VEC_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[TYPE_ID]] 4
// CHECK-DAG: %[[GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[VEC_TYPE_ID]]
// CHECK-DAG: %[[DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[VEC_TYPE_ID]]
// CHECK-DAG: %[[ARG_STRUCT_TYPE_ID]] = OpTypeStruct %[[DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[ARG_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG_STRUCT_TYPE_ID]]
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK-DAG: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: %[[ARG0_ID]] = OpVariable %[[ARG_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG1_ID]] = OpVariable %[[ARG_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float4* b)
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
{
// CHECK: %[[LOADA_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOADB_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[GLOBAL_POINTER_TYPE_ID]] %[[ARG1_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[VEC_TYPE_ID]] %[[LOADB_ACCESS_CHAIN_ID]]
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpLoad %[[VEC_TYPE_ID]] %[[LOADA_ACCESS_CHAIN_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpFSub %[[VEC_TYPE_ID]] %[[LOADA_ID]] %[[LOADB_ID]]
// CHECK: OpStore %[[LOADA_ACCESS_CHAIN_ID]] %[[OP_ID]]
  *a -= *b;
// CHECK: OpReturn
}
// CHECK: OpFunctionEnd
