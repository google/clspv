// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 22
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1
// CHECK: OpDecorate %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 16
// CHECK: OpMemberDecorate %[[FLOAT_ARG_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[FLOAT_ARG_STRUCT_TYPE_ID]] Block
// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0
// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG1_ID]] Binding 1
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 3
// CHECK-DAG: %[[FLOAT_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_ARG_STRUCT_TYPE_ID]] = OpTypeStruct %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_ARG_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_ARG_STRUCT_TYPE_ID]]
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK-DAG: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_FLOAT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 1
// CHECK-DAG: %[[COMPOSITE_FLOAT_1_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[FLOAT_VECTOR_TYPE_ID]] %[[CONSTANT_FLOAT_1_ID]] %[[CONSTANT_FLOAT_1_ID]] %[[CONSTANT_FLOAT_1_ID]]
// CHECK: %[[ARG0_ID]] = OpVariable %[[FLOAT_ARG_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG1_ID]] = OpVariable %[[FLOAT_ARG_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[A_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[B_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_GLOBAL_POINTER_TYPE_ID]] %[[ARG1_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]] %[[B_ACCESS_CHAIN_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_VECTOR_TYPE_ID]] %[[EXT_INST]] Pow %[[LOADB_ID]] %[[COMPOSITE_FLOAT_1_ID]]
// CHECK: OpStore %[[A_ACCESS_CHAIN_ID]] %[[OP_ID]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float3* a, global float3* b)
{
  *a = powr(*b, 1.0f);
}
