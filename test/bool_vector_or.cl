// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 40
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1
// CHECK: OpMemberDecorate %[[FLOAT_ARG_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[FLOAT_ARG_STRUCT_TYPE_ID]] Block
// CHECK: OpDecorate %[[INT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 16
// CHECK: OpMemberDecorate %[[INT_ARG_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[INT_ARG_STRUCT_TYPE_ID]] Block
// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0
// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG1_ID]] Binding 1
// CHECK: OpDecorate %[[ARG2_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG2_ID]] Binding 2
// CHECK: OpDecorate %[[ARG3_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG3_ID]] Binding 3
// CHECK: OpDecorate %[[ARG4_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG4_ID]] Binding 4
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[FLOAT_ARG_STRUCT_TYPE_ID]] = OpTypeStruct %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_ARG_STRUCT_TYPE_ID]]
// CHECK-DAG: %[[INT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[INT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[INT_TYPE_ID]] 4
// CHECK-DAG: %[[INT_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[INT_VECTOR_TYPE_ID]]
// CHECK-DAG: %[[INT_ARG_STRUCT_TYPE_ID]] = OpTypeStruct %[[INT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[INT_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[INT_ARG_STRUCT_TYPE_ID]]
// CHECK-DAG: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK-DAG: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_ARG_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK-DAG: %[[INT_ARG_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[INT_VECTOR_TYPE_ID]]
// CHECK: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK: %[[BOOL_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[BOOL_TYPE_ID]] 4
// CHECK: %[[CONSTANT_NULL_ID:[a-zA-Z0-9]*]] = OpConstantNull %[[INT_VECTOR_TYPE_ID]]
// CHECK: %[[CONSTANT_MAXINT_ID:[a-zA-Z0-9_]*]] = OpConstant %[[INT_TYPE_ID]] 4294967295
// CHECK: %[[CONSTANT_MAXINT_VECTOR_ID:[a-zA-Z0-9]*]] = OpConstantComposite %[[INT_VECTOR_TYPE_ID]] %[[CONSTANT_MAXINT_ID]] %[[CONSTANT_MAXINT_ID]] %[[CONSTANT_MAXINT_ID]] %[[CONSTANT_MAXINT_ID]]
// CHECK: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[INT_TYPE_ID]] 0
// CHECK: %[[ARG0_ID]] = OpVariable %[[FLOAT_GLOBAL_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG1_ID]] = OpVariable %[[FLOAT_GLOBAL_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG2_ID]] = OpVariable %[[FLOAT_GLOBAL_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG3_ID]] = OpVariable %[[FLOAT_GLOBAL_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG4_ID]] = OpVariable %[[INT_GLOBAL_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[A_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_ARG_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]] %[[A_ACCESS_CHAIN_ID]]
// CHECK: %[[B_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_ARG_POINTER_TYPE_ID]] %[[ARG1_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]] %[[B_ACCESS_CHAIN_ID]]
// CHECK: %[[C_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_ARG_POINTER_TYPE_ID]] %[[ARG2_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOADC_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]] %[[C_ACCESS_CHAIN_ID]]
// CHECK: %[[D_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_ARG_POINTER_TYPE_ID]] %[[ARG3_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOADD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]] %[[D_ACCESS_CHAIN_ID]]
// CHECK: %[[O_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[INT_ARG_POINTER_TYPE_ID]] %[[ARG4_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[COMP1_RES_ID:[a-zA-Z0-9]*]] = OpFOrdLessThanEqual %[[BOOL_VECTOR_TYPE_ID]] %[[LOADA_ID]] %[[LOADB_ID]]
// CHECK: %[[COMP2_RES_ID:[a-zA-Z0-9]*]] = OpFOrdGreaterThan %[[BOOL_VECTOR_TYPE_ID]] %[[LOADC_ID]] %[[LOADD_ID]]
// CHECK: %[[LOGICAL_RES_ID:[a-zA-Z0-9]*]] = OpLogicalOr %[[BOOL_VECTOR_TYPE_ID]] %[[COMP2_RES_ID]] %[[COMP1_RES_ID]]
// CHECK: %[[SELECT_ID:[a-zA-Z0-9]*]] = OpSelect %[[INT_VECTOR_TYPE_ID]] %[[LOGICAL_RES_ID]] %[[CONSTANT_MAXINT_VECTOR_ID]] %[[CONSTANT_NULL_ID]]
// CHECK: OpStore %[[O_ACCESS_CHAIN_ID]] %[[SELECT_ID]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(float4 a, float4 b, float4 c, float4 d, global int4 *o)
{
    int4 ab = (a <= b);
    int4 cd = (c > d);
    *o = (ab || cd);
}
