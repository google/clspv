// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 21
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1
// CHECK: OpDecorate %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 4
// CHECK: OpMemberDecorate %[[FLOAT_ARG0_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[FLOAT_ARG0_STRUCT_TYPE_ID]] Block
// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[FLOAT_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_ARG0_STRUCT_TYPE_ID]] = OpTypeStruct %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_ARG0_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_ARG0_STRUCT_TYPE_ID]]
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK-DAG: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 1
// CHECK-DAG: %[[CONSTANT_UINT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 42
// CHECK: %[[ARG0_ID]] = OpVariable %[[FLOAT_ARG0_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a)
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
{
// CHECK: %[[ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_UINT_0_ID]] %[[CONSTANT_UINT_0_ID]]
// CHECK: %[[LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]] %[[ACCESS_CHAIN_ID]]
  const float aLoad = *a;

// CHECK: %[[CMP_ID:[a-zA-Z0-9_]*]] = OpFOrdEqual %[[BOOL_TYPE_ID]] %[[LOAD_ID]] %[[CONSTANT_42_ID]]
  const bool c = (aLoad == 42.0f);

// CHECK: %[[CAS_ID:[a-zA-Z0-9_]*]] = OpSelect %[[FLOAT_TYPE_ID]] %[[CMP_ID]] %[[CONSTANT_1_ID]] %[[CONSTANT_0_ID]]
  const float cAs = c;

// CHECK: OpStore %[[ACCESS_CHAIN_ID]] %[[CAS_ID]]
  *a = cAs;

// CHECK: OpReturn
}
// CHECK: OpFunctionEnd
