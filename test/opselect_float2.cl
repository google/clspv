// Test https://github.com/google/clspv/issues/65
// OpSelect with vector data operands must use vector bool selector.

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float2* A, int c)
{
  *A = c ? (float2)(1.0,2.0) : (float2)(3.0,4.0);
}

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
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1

// CHECK: OpDecorate %[[ARG0_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 8
// CHECK: OpMemberDecorate %[[ARG0_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG0_STRUCT_TYPE_ID]] Block

// CHECK: OpMemberDecorate %[[s_uint:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[s_uint]] Block

// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0
// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG1_ID]] Binding 1

// CHECK-DAG: %[[float:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[float2:[a-zA-Z0-9_]*]] = OpTypeVector %[[float]] 2


// For the A argument:
// CHECK-DAG: %[[ARG0_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[float2]]
// CHECK-DAG: %[[ARG0_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[float2]]
// CHECK-DAG: %[[ARG0_STRUCT_TYPE_ID]] = OpTypeStruct %[[ARG0_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[ARG0_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG0_STRUCT_TYPE_ID]]

// For the n argument:
// CHECK-DAG: %[[uint:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[s_uint]] = OpTypeStruct %[[uint]]
// CHECK-DAG: %[[ptr_s_uint:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[s_uint]]
// CHECK-DAG: %[[ptr_uint:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[uint]]


// CHECK-DAG: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK-DAG: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[bool2:[a-zA-Z0-9_]*]] = OpTypeVector %[[BOOL_TYPE_ID]] 2

// CHECK-DAG: %[[uint_0:[a-zA-Z0-9_]*]] = OpConstant %[[uint]] 0
// CHECK: %[[undef:[a-zA-Z0-9_]*]] = OpUndef %[[bool2]]
// CHECK-DAG: %[[float_3:[a-zA-Z0-9_]*]] = OpConstant %[[float]] 3
// CHECK-DAG: %[[float_4:[a-zA-Z0-9_]*]] = OpConstant %[[float]] 4
// CHECK-DAG: %[[v2_3_4:[a-zA-Z0-9_]*]] = OpConstantComposite %[[float2]] %[[float_3]] %[[float_4]]
// CHECK-DAG: %[[float_1:[a-zA-Z0-9_]*]] = OpConstant %[[float]] 1
// CHECK-DAG: %[[float_2:[a-zA-Z0-9_]*]] = OpConstant %[[float]] 2
// CHECK-DAG: %[[v2_1_2:[a-zA-Z0-9_]*]] = OpConstantComposite %[[float2]] %[[float_1]] %[[float_2]]


// CHECK: %[[ARG0_ID]] = OpVariable %[[ARG0_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG1_ID]] = OpVariable %[[ptr_s_uint]] StorageBuffer


// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[A_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[ARG0_GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[uint_0]] %[[uint_0]]
// CHECK: %[[n_ptr:[a-zA-Z0-9_]*]] = OpAccessChain %[[ptr_uint]] %[[ARG1_ID]] %[[uint_0]]

// CHECK: %[[n:[a-zA-Z0-9_]*]] = OpLoad %[[uint]] %[[n_ptr]]
// CHECK: %[[eq:[a-zA-Z0-9_]*]] = OpIEqual %[[BOOL_TYPE_ID]] %[[n]] %[[uint_0]]

// CHECK: %[[eq_vec0:[a-zA-Z0-9_]*]] = OpCompositeInsert %[[bool2]] %[[eq]] %[[undef]] 0
// CHECK: %[[eq_splat:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[bool2]] %[[eq_vec0]] %[[undef]] 0 0

// CHECK: %[[sel:[a-zA-Z0-9_]*]] = OpSelect %[[float2]] %[[eq_splat]] %[[v2_3_4]] %[[v2_1_2]]
// CHECK: OpStore %[[A_ACCESS_CHAIN_ID]] %[[sel]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
