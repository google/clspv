// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
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
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1
// CHECK: OpDecorate %[[UINT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 4
// CHECK: OpMemberDecorate %[[ARG0_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG0_STRUCT_TYPE_ID]] Block
// CHECK: OpMemberDecorate %[[ARG1_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG1_STRUCT_TYPE_ID]] Block
// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0
// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG1_ID]] Binding 1
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_TYPE_ID]]
// CHECK-DAG: %[[UINT_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[UINT_TYPE_ID]]
// CHECK-DAG: %[[ARG0_STRUCT_TYPE_ID]] = OpTypeStruct %[[UINT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[ARG0_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG0_STRUCT_TYPE_ID]]
// CHECK-DAG: %[[ARG1_STRUCT_TYPE_ID]] = OpTypeStruct %[[UINT_TYPE_ID]]
// CHECK-DAG: %[[ARG1_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG1_STRUCT_TYPE_ID]]
// CHECK-DAG: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK-DAG: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1
// CHECK: %[[ARG0_ID]] = OpVariable %[[ARG0_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG1_ID]] = OpVariable %[[ARG1_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[B_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[ARG1_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOAD_B_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[B_ACCESS_CHAIN_ID]]
// CHECK: %[[CMP_0_ID:[a-zA-Z0-9_]*]] = OpIEqual %[[BOOL_TYPE_ID]] %[[LOAD_B_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[NOT_CMP_0_ID:[a-zA-Z0-9_]*]] = OpLogicalNot %[[BOOL_TYPE_ID]] %[[CMP_0_ID]]

// CHECK: OpSelectionMerge [[sel_merge_id:%[0-9]+]] None
// CHECK: OpBranchConditional %[[NOT_CMP_0_ID]] [[loop_preheader:%[0-9]+]] [[sel_merge_id]]

// CHECK: [[loop_preheader]] = OpLabel
// CHECK: OpBranch [[loop_body_id:%[0-9]+]]

// CHECK: [[loop_body_id]] = OpLabel
// CHECK: %[[PHI_ID:[a-zA-Z0-9_]*]] = OpPhi %[[UINT_TYPE_ID]] %[[INCREMENT_PHI_ID:[a-zA-Z0-9_]*]] [[loop_body_id]] %[[CONSTANT_0_ID]] [[loop_preheader]]
// CHECK: %[[A_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[PHI_ID]]
// CHECK: %[[LOAD_A_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[A_ACCESS_CHAIN_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpIAdd %[[UINT_TYPE_ID]] %[[LOAD_A_ID]] %[[CONSTANT_1_ID]]
// CHECK: OpStore %[[A_ACCESS_CHAIN_ID]] %[[OP_ID]]
// CHECK: %[[INCREMENT_PHI_ID]] = OpIAdd %[[UINT_TYPE_ID]] %[[PHI_ID]] %[[CONSTANT_1_ID]]
// CHECK: %[[CMP_1_ID:[a-zA-Z0-9_]*]] = OpULessThan %[[BOOL_TYPE_ID]] %[[INCREMENT_PHI_ID]] %[[LOAD_B_ID]]
// CHECK: %[[NOT_CMP_1_ID:[a-zA-Z0-9_]*]] = OpLogicalNot %[[BOOL_TYPE_ID]] %[[CMP_1_ID]]
// CHECK: OpLoopMerge %[[MERGE_ID:[a-zA-Z0-9_]*]] [[loop_body_id]] None
// CHECK: OpBranchConditional %[[NOT_CMP_1_ID]] %[[MERGE_ID]] [[loop_body_id]]

// CHECK: %[[MERGE_ID]] = OpLabel
// CHECK: OpBranch [[sel_merge_id]]

// CHECK: [[sel_merge_id]] = OpLabel
// CHECK: OpBranch [[END_LABEL_ID:%[0-9]+]]

// CHECK: [[END_LABEL_ID]] = OpLabel
// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, uint b)
{
  for (uint i = 0; i < b; i++)
  {
    a[i]++;
  }
}
