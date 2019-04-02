// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 32
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpDecorate %[[BUILTIN_X_ID:[a-zA-Z0-9_]*]] SpecId 0
// CHECK: OpDecorate %[[BUILTIN_Y_ID:[a-zA-Z0-9_]*]] SpecId 1
// CHECK: OpDecorate %[[BUILTIN_Z_ID:[a-zA-Z0-9_]*]] SpecId 2
// CHECK: OpDecorate %[[UINT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 4
// CHECK: OpMemberDecorate %[[UINT_ARG0_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[UINT_ARG0_STRUCT_TYPE_ID]] Block
// CHECK: OpDecorate %[[BUILTIN_ID:[a-zA-Z0-9_]*]] BuiltIn WorkgroupSize
// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT_GLOBAL_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_TYPE_ID]]
// CHECK-DAG: %[[UINT_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[UINT_TYPE_ID]]
// CHECK-DAG: %[[UINT_ARG0_STRUCT_TYPE_ID]] = OpTypeStruct %[[UINT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[UINT_ARG0_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_ARG0_STRUCT_TYPE_ID]]
// CHECK-DAG: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK-DAG: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK-DAG: %[[UINT3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 3
// CHECK-DAG: %[[UINT3_PRIVATE_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer Private %[[UINT3_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1
// CHECK-DAG: %[[CONSTANT_2_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 2
// CHECK-DAG: %[[CONSTANT_3_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 3
// CHECK: %[[BUILTIN_X_ID]] = OpSpecConstant %[[UINT_TYPE_ID]] 1
// CHECK: %[[BUILTIN_Y_ID]] = OpSpecConstant %[[UINT_TYPE_ID]] 1
// CHECK: %[[BUILTIN_Z_ID]] = OpSpecConstant %[[UINT_TYPE_ID]] 1
// CHECK: %[[BUILTIN_ID]] = OpSpecConstantComposite %[[UINT3_TYPE_ID]] %[[BUILTIN_X_ID]] %[[BUILTIN_Y_ID]] %[[BUILTIN_Z_ID]]
// CHECK: %[[BUILTIN_VAR_ID:[a-zA-Z0-9_]*]] = OpVariable %[[UINT3_PRIVATE_POINTER_TYPE_ID]] Private %[[BUILTIN_ID]]
// CHECK: %[[ARG0_ID]] = OpVariable %[[UINT_ARG0_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL1_ID:[a-zA-Z0-9_]*]] = OpLabel

// CHECK: %[[ACCESS_CHAIN0_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: [[hack0:%[a-zA-Z0-9_]+]] = OpBitwiseAnd %[[UINT3_TYPE_ID]] %[[BUILTIN_ID]] %[[BUILTIN_ID]]
// CHECK: [[comp0:%[a-zA-Z0-9_]+]] = OpCompositeExtract %[[UINT_TYPE_ID]] [[hack0]] 0
// CHECK: OpStore %[[ACCESS_CHAIN0_ID]] [[comp0]]

// CHECK: [[hack1:%[a-zA-Z0-9_]+]] = OpBitwiseAnd %[[UINT3_TYPE_ID]] %[[BUILTIN_ID]] %[[BUILTIN_ID]]
// CHECK: [[comp1:%[a-zA-Z0-9_]+]] = OpCompositeExtract %[[UINT_TYPE_ID]] [[hack1]]
// CHECK: %[[ACCESS_CHAIN1_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_1_ID]]
// CHECK: OpStore %[[ACCESS_CHAIN1_ID]] [[comp1]]

// CHECK: [[hack2:%[a-zA-Z0-9_]+]] = OpBitwiseAnd %[[UINT3_TYPE_ID]] %[[BUILTIN_ID]] %[[BUILTIN_ID]]
// CHECK: [[comp2:%[a-zA-Z0-9_]+]] = OpCompositeExtract %[[UINT_TYPE_ID]] [[hack2]]
// CHECK: %[[ACCESS_CHAIN2_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_2_ID]]
// CHECK: OpStore %[[ACCESS_CHAIN2_ID]] [[comp2]]

// CHECK: %[[ACCESS_CHAIN3_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_GLOBAL_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_3_ID]]
// CHECK: OpStore %[[ACCESS_CHAIN3_ID]] %[[CONSTANT_1_ID]]

// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel foo(global uint* a)
{
  a[0] = get_local_size(0);
  a[1] = get_local_size(1);
  a[2] = get_local_size(2);
  a[3] = get_local_size(3);
}
