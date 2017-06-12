// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 30
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate %[[DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 4
// CHECK: OpMemberDecorate %[[STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[STRUCT_TYPE_ID]] BufferBlock
// CHECK: OpMemberDecorate %[[INT_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[INT_STRUCT_TYPE_ID]] BufferBlock
// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0
// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG1_ID]] Binding 1
// CHECK: OpDecorate %[[ARG2_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG2_ID]] Binding 2

// CHECK: %[[INT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK: %[[INT_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[INT_TYPE_ID]]
// CHECK: %[[DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[INT_TYPE_ID]]
// CHECK: %[[STRUCT_TYPE_ID]] = OpTypeStruct %[[DYNAMIC_ARRAY_TYPE_ID]]
// CHECK: %[[STRUCT_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[STRUCT_TYPE_ID]]
// CHECK: %[[INT_STRUCT_TYPE_ID]] = OpTypeStruct %[[INT_TYPE_ID]]
// CHECK: %[[POINTER_INT_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[INT_STRUCT_TYPE_ID]]
// CHECK: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool

// CHECK: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[INT_TYPE_ID]] 0
// CHECK: %[[CONSTANT_100_ID:[a-zA-Z0-9_]*]] = OpConstant %[[INT_TYPE_ID]] 100
// CHECK: %[[CONSTANT_50_ID:[a-zA-Z0-9_]*]] = OpConstant %[[INT_TYPE_ID]] 50
// CHECK: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[INT_TYPE_ID]] 1

// CHECK: %[[ARG0_ID]] = OpVariable %[[STRUCT_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG1_ID]] = OpVariable %[[POINTER_INT_STRUCT_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG2_ID]] = OpVariable %[[POINTER_INT_STRUCT_TYPE_ID]] StorageBuffer

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[ARG0_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[INT_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[ARG1_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[INT_POINTER_TYPE_ID]] %[[ARG1_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[ARG1_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[INT_TYPE_ID]] %[[ARG1_ACCESS_CHAIN_ID]]
// CHECK: %[[ARG2_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[INT_POINTER_TYPE_ID]] %[[ARG2_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[ARG2_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[INT_TYPE_ID]] %[[ARG2_ACCESS_CHAIN_ID]]
// CHECK: %[[LT_ID:[a-zA-Z0-9_]*]] = OpSLessThan %[[BOOL_TYPE_ID]] %[[ARG1_LOAD_ID]] %[[CONSTANT_100_ID]]
// CHECK: %[[GT_ID:[a-zA-Z0-9_]*]] = OpSGreaterThan %[[BOOL_TYPE_ID]] %[[ARG2_LOAD_ID]] %[[CONSTANT_50_ID]]
// CHECK: %[[AND_ID:[a-zA-Z0-9_]*]] = OpLogicalAnd %[[BOOL_TYPE_ID]] %[[LT_ID]] %[[GT_ID]]
// CHECK: OpSelectionMerge %[[MERGE_ID:[a-zA-Z0-9_]*]] None
// CHECK: OpBranchConditional %[[AND_ID]] %[[IF_ID:[a-zA-Z0-9_]*]] %[[MERGE_ID]]
// CHECK: %[[IF_ID]] = OpLabel
// CHECK: OpStore %[[ARG0_ACCESS_CHAIN_ID]] %[[CONSTANT_1_ID]]
// CHECK: OpBranch %[[MERGE_ID]]
// CHECK: %[[MERGE_ID]] = OpLabel
// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int *out, int m, int n)
{
  bool a = m < 100;
  bool b = n > 50;
  if (a && b)
  {
    *out = 1;
  }
}
