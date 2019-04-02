// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 33
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1

// CHECK: OpDecorate %[[ARG0_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 8
// CHECK: OpMemberDecorate %[[ARG0_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG0_STRUCT_TYPE_ID]] Block

// CHECK: OpDecorate %[[ARG1_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 8
// CHECK: OpMemberDecorate %[[ARG1_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG1_STRUCT_TYPE_ID]] Block

// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0

// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG1_ID]] Binding 1

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 2

// CHECK-DAG: %[[ARG0_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT2_TYPE_ID]]
// CHECK-DAG: %[[ARG0_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[UINT2_TYPE_ID]]
// CHECK-DAG: %[[ARG0_STRUCT_TYPE_ID]] = OpTypeStruct %[[ARG0_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[ARG0_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG0_STRUCT_TYPE_ID]]

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2

// CHECK-DAG: %[[ARG1_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT2_TYPE_ID]]
// CHECK-DAG: %[[ARG1_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[FLOAT2_TYPE_ID]]
// CHECK-DAG: %[[ARG1_STRUCT_TYPE_ID]] = OpTypeStruct %[[ARG1_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[ARG1_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG1_STRUCT_TYPE_ID]]

// CHECK-DAG: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK-DAG: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[BOOL2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[BOOL_TYPE_ID]] 2

// CHECK-DAG: %[[UINT2_CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstantNull %[[UINT2_TYPE_ID]]

// CHECK-DAG: %[[CONSTANT_ALL_BITS_SET_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 4294967295
// CHECK-DAG: %[[UINT2_CONSTANT_ALL_BITS_SET_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[UINT2_TYPE_ID]] %[[CONSTANT_ALL_BITS_SET_ID]] %[[CONSTANT_ALL_BITS_SET_ID]]

// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1

// CHECK: %[[ARG0_ID]] = OpVariable %[[ARG0_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG1_ID]] = OpVariable %[[ARG1_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[A_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[ARG0_GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[B0_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[ARG1_GLOBAL_POINTER_TYPE_ID]] %[[ARG1_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[B0_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT2_TYPE_ID]] %[[B0_ACCESS_CHAIN_ID]]
// CHECK: %[[B1_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[ARG1_GLOBAL_POINTER_TYPE_ID]] %[[ARG1_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_1_ID]]
// CHECK: %[[B1_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT2_TYPE_ID]] %[[B1_ACCESS_CHAIN_ID]]
// CHECK: %[[CMP_ID:[a-zA-Z0-9_]*]] = OpFOrdLessThanEqual %[[BOOL2_TYPE_ID]] %[[B0_LOAD_ID]] %[[B1_LOAD_ID]]
// CHECK: %[[CAS_ID:[a-zA-Z0-9_]*]] = OpSelect %[[UINT2_TYPE_ID]] %[[CMP_ID]] %[[UINT2_CONSTANT_ALL_BITS_SET_ID]] %[[UINT2_CONSTANT_0_ID]]
// CHECK: OpStore %[[A_ACCESS_CHAIN_ID]] %[[CAS_ID]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int2* a, global float2* b)
{
  *a = islessequal(b[0], b[1]);
}
