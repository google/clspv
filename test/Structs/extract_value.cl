// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 29
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 42 13 2
// CHECK: OpDecorate %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 4

// CHECK: OpMemberDecorate %[[ARG_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG_STRUCT_TYPE_ID]] Block
// CHECK: OpMemberDecorate %[[THING_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpMemberDecorate %[[THING_TYPE_ID]] 1 Offset 4
// CHECK: OpDecorate %[[ARG_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG_ID]] Binding 0

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[FLOAT_TYPE_ID]]
// CHECK-DAG: %[[ARG_STRUCT_TYPE_ID]] = OpTypeStruct %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[ARG_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG_STRUCT_TYPE_ID]]
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK-DAG: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK-DAG: %[[THING_TYPE_ID]] = OpTypeStruct %[[FLOAT_TYPE_ID]] %[[FLOAT_TYPE_ID]]



struct Thing {
  float x;
  float y;
};


// CHECK-DAG: %[[A_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[THING_TYPE_ID]]
// CHECK-DAG: %[[B_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[FLOAT_TYPE_ID]]

// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 42
// CHECK-DAG: %[[CONSTANT_2_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 2
// CHECK-DAG: %[[CONSTANT_STRUCT_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[THING_TYPE_ID]] %[[CONSTANT_42_ID]] %[[CONSTANT_2_ID]]

// CHECK: %[[ARG_ID]] = OpVariable %[[ARG_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[A_ID:[a-zA-Z0-9_]*]] = OpFunction %[[THING_TYPE_ID]] Const %[[A_TYPE_ID]]
// CHECK: %[[A_LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: OpReturnValue %[[CONSTANT_STRUCT_ID]]
// CHECK: OpFunctionEnd

struct Thing a() {
  struct Thing x;
  x.x = 42.0f;
  x.y = 2.0f;
  return x;
}

// CHECK: %[[B_ID:[a-zA-Z0-9_]*]] = OpFunction %[[FLOAT_TYPE_ID]] Const %[[B_TYPE_ID]]
// CHECK: %[[B_LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[CALL_A_ID:[a-zA-Z0-9_]*]] = OpFunctionCall %[[THING_TYPE_ID]] %[[A_ID]]
// CHECK: %[[X_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[CALL_A_ID]] 0
// CHECK: %[[Y_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[CALL_A_ID]] 1
// CHECK: %[[MUL_ID:[a-zA-Z0-9_]*]] = OpFMul %[[FLOAT_TYPE_ID]] %[[X_ID]] %[[Y_ID]]
// CHECK: OpReturnValue %[[MUL_ID]]
// CHECK: OpFunctionEnd

float b() {
  return a().x * a().y;
}

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] None %[[FOO_TYPE_ID]]
// CHECK: %[[FOO_LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_POINTER_TYPE_ID]] %[[ARG_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[CALL_B_ID:[a-zA-Z0-9_]*]] = OpFunctionCall %[[FLOAT_TYPE_ID]] %[[B_ID]]
// CHECK: OpStore %[[ACCESS_CHAIN_ID]] %[[CALL_B_ID]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(42, 13, 2))) foo(global float* x) {
  *x = b();
}
