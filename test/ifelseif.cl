// We use -O0 here to ensure we thoroughly test that our CFG is structured.
// RUN: clspv -O0 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Bound: 30
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
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 42
// CHECK-DAG: %[[CONSTANT_5_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 5
// CHECK-DAG: %[[CONSTANT_FALSE_ID:[a-zA-Z0-9_]*]] = OpConstantFalse %[[BOOL_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_TRUE_ID:[a-zA-Z0-9_]*]] = OpConstantTrue %[[BOOL_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_13_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 13

// CHECK: %[[ARG0_ID]] = OpVariable %[[UINT_ARG0_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[ACCESS_CHAIN_ID]]
// CHECK: %[[CMP0_ID:[a-zA-Z0-9_]*]] = OpUGreaterThan %[[BOOL_TYPE_ID]] %[[LOAD_ID]] %[[CONSTANT_42_ID]]
// CHECK: %[[NOT_CMP0_ID:[a-zA-Z0-9_]*]] = OpLogicalNot %[[BOOL_TYPE_ID]] %[[CMP0_ID]]
// CHECK: OpSelectionMerge %[[MERGE0_LABEL_ID:[a-zA-Z0-9_]*]] None
// CHECK: OpBranchConditional %[[NOT_CMP0_ID]] %[[MERGE2_LABEL_ID:[a-zA-Z0-9_]*]] %[[MERGE0_LABEL_ID]]

// CHECK: %[[MERGE2_LABEL_ID]] = OpLabel
// CHECK: %[[CMP1_ID:[a-zA-Z0-9_]*]] = OpIEqual %[[BOOL_TYPE_ID]] %[[LOAD_ID]] %[[CONSTANT_42_ID]]
// CHECK: OpSelectionMerge %[[MERGE1_LABEL_ID:[a-zA-Z0-9_]*]] None
// CHECK: OpBranchConditional %[[CMP1_ID]] %[[ELSEIF_LABEL_ID:[a-zA-Z0-9_]*]] %[[MERGE1_LABEL_ID]]

// CHECK: %[[ELSEIF_LABEL_ID]] = OpLabel
// CHECK: OpStore %[[ACCESS_CHAIN_ID]] %[[CONSTANT_5_ID]]
// CHECK: OpBranch %[[MERGE1_LABEL_ID]]

// CHECK: %[[MERGE1_LABEL_ID]] = OpLabel
// CHECK: OpBranch %[[MERGE0_LABEL_ID]]

// CHECK: %[[MERGE0_LABEL_ID]] = OpLabel
// CHECK: %[[PHI_ID:[a-zA-Z0-9_]*]] = OpPhi %[[BOOL_TYPE_ID]] %[[CONSTANT_FALSE_ID]] %[[MERGE1_LABEL_ID]] %[[CONSTANT_TRUE_ID]] %[[LABEL_ID]]
// CHECK: OpSelectionMerge %[[END_LABEL_ID:[a-zA-Z0-9_]*]] None
// CHECK: OpBranchConditional %[[PHI_ID]] %[[IF_LABEL_ID:[a-zA-Z0-9_]*]] %[[END_LABEL_ID]]

// CHECK: %[[END_LABEL_ID]] = OpLabel
// CHECK: OpReturn

// CHECK: %[[IF_LABEL_ID]] = OpLabel
// CHECK: OpStore %[[ACCESS_CHAIN_ID]] %[[CONSTANT_13_ID]]
// CHECK: OpBranch %[[END_LABEL_ID]]
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a)
{
  const uint aLoad = *a;
  const bool c0 = (aLoad > 42);
  const bool c1 = (aLoad == 42);

  if (c0)
  {
    *a = 13;
  }
  else if (c1)
  {
    *a = 5;
  }
}
