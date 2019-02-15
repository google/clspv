// We use -O0 here because get_work_dim() always returns 3, and otherwise
// the compiler is smart enough to optimize everything away!
// RUN: clspv -O0 %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv -O0 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 19
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1
// CHECK: OpDecorate %[[UINT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 4
// CHECK: OpMemberDecorate %[[UINT_ARG0_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[UINT_ARG0_STRUCT_TYPE_ID]] Block
// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_TYPE_ID]]
// CHECK-DAG: %[[UINT_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[UINT_TYPE_ID]]
// CHECK-DAG: %[[UINT_ARG0_STRUCT_TYPE_ID]] = OpTypeStruct %[[UINT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[UINT_ARG0_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_ARG0_STRUCT_TYPE_ID]]
// CHECK-DAG: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK-DAG: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK-DAG: %[[GET_WORK_DIM_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[UINT_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_3_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 3
// CHECK: %[[ARG0_ID]] = OpVariable %[[UINT_ARG0_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL1_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[RESULT1_ID:[a-zA-Z0-9_]*]] = OpFunctionCall %[[UINT_TYPE_ID]] %[[GET_WORK_DIM_ID:[a-zA-Z0-9_]*]]
// CHECK: %[[RESULT2_ID:[a-zA-Z0-9_]*]] = OpFunctionCall %[[UINT_TYPE_ID]] %[[GET_WORK_DIM_ID:[a-zA-Z0-9_]*]]
// CHECK: %[[ACCESS_CHAIN1_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[RESULT2_ID]]
// CHECK: OpStore %[[ACCESS_CHAIN1_ID]] %[[RESULT1_ID]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a)
{
  a[get_work_dim()] = get_work_dim();
}

// CHECK: %[[GET_WORK_DIM_ID]] = OpFunction %[[UINT_TYPE_ID]] Const %[[GET_WORK_DIM_TYPE_ID]]
// CHECK: %[[LABEL2_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: OpReturnValue %[[CONSTANT_3_ID]]
// CHECK: OpFunctionEnd
