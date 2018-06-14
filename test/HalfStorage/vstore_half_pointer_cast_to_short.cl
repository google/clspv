// RUN: clspv %s -S -o %t.spvasm -f16bit_storage
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -f16bit_storage
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 28
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability Int16
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1

// CHECK: OpDecorate %[[SHORT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 2
// CHECK: OpMemberDecorate %[[ARG0_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG0_STRUCT_TYPE_ID]] Block

// CHECK: OpDecorate %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 4
// CHECK: OpMemberDecorate %[[ARG1_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG1_STRUCT_TYPE_ID]] Block

// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0
// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG1_ID]] Binding 1

// CHECK-DAG: %[[SHORT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 16 0
// CHECK-DAG: %[[SHORT_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[SHORT_TYPE_ID]]
// CHECK-DAG: %[[SHORT_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[SHORT_TYPE_ID]]
// CHECK-DAG: %[[ARG0_STRUCT_TYPE_ID]] = OpTypeStruct %[[SHORT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[ARG0_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG0_STRUCT_TYPE_ID]]

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[FLOAT_TYPE_ID]]
// CHECK-DAG: %[[ARG1_STRUCT_TYPE_ID]] = OpTypeStruct %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[ARG1_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG1_STRUCT_TYPE_ID]]

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK-DAG: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK-DAG: %[[FLOAT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2

// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: %[[UNDEF_ID:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT2_TYPE_ID]]

// CHECK: %[[ARG0_ID]] = OpVariable %[[ARG0_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG1_ID]] = OpVariable %[[ARG1_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel

// CHECK: %[[A_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[SHORT_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[B_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_POINTER_TYPE_ID]] %[[ARG1_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]

// CHECK: %[[LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]] %[[B_ACCESS_CHAIN_ID]]
// CHECK: %[[INSERT_ID:[a-zA-Z0-9_]*]] = OpCompositeInsert %[[FLOAT2_TYPE_ID]] %[[LOAD_ID]] %[[UNDEF_ID]] 0
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[UINT_TYPE_ID]] %[[EXT_INST]] PackHalf2x16 %[[INSERT_ID]]
// CHECK: %[[CONVERT_ID:[a-zA-Z0-9_]*]] = OpUConvert %[[SHORT_TYPE_ID]] %[[OP_ID]]
// CHECK: OpStore %[[A_ACCESS_CHAIN_ID]] %[[CONVERT_ID]]

// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global short* a, global float* b)
{
  vstore_half(*b, 0, (global half *)a);
}
