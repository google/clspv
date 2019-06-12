// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK-NOT: OpCapability Int16
// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID:[a-zA-Z0-9_]*]] LocalSize 1 1 1

// CHECK: OpDecorate %[[UINT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 4
// CHECK: OpMemberDecorate %[[ARG0_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG0_STRUCT_TYPE_ID]] Block

// CHECK: OpDecorate %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 4
// CHECK: OpMemberDecorate %[[ARG1_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG1_STRUCT_TYPE_ID]] Block

// CHECK: OpMemberDecorate %[[ARG2_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG2_STRUCT_TYPE_ID]] Block

// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0
// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG1_ID]] Binding 1
// CHECK: OpDecorate %[[ARG2_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG2_ID]] Binding 2

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[UINT_TYPE_ID]]
// CHECK-DAG: %[[UINT_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[UINT_TYPE_ID]]
// CHECK-DAG: %[[ARG0_STRUCT_TYPE_ID]] = OpTypeStruct %[[UINT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[ARG0_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG0_STRUCT_TYPE_ID]]

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[FLOAT_TYPE_ID]]
// CHECK-DAG: %[[ARG1_STRUCT_TYPE_ID]] = OpTypeStruct %[[FLOAT_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[ARG1_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG1_STRUCT_TYPE_ID]]

// CHECK-DAG: %[[ARG2_STRUCT_TYPE_ID]] = OpTypeStruct %[[UINT_TYPE_ID]]
// CHECK-DAG: %[[ARG2_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG2_STRUCT_TYPE_ID]]

// CHECK-DAG: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK-DAG: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK-DAG: %[[FLOAT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2

// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: %[[UNDEF_ID:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT2_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1
// CHECK-DAG: %[[CONSTANT_4_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 4
// CHECK-DAG: %[[CONSTANT_16_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 16
// CHECK-DAG: %[[CONSTANT_65535_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 65535
// CHECK-DAG: %[[CONSTANT_64_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 64

// CHECK: %[[ARG0_ID]] = OpVariable %[[ARG0_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG1_ID]] = OpVariable %[[ARG1_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG2_ID]] = OpVariable %[[ARG2_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel

// CHECK: %[[B_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT_POINTER_TYPE_ID]] %[[ARG1_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[N_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_POINTER_TYPE_ID]] %[[ARG2_ID]] %[[CONSTANT_0_ID]]

// CHECK: %[[N:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[N_ACCESS_CHAIN_ID]]
// CHECK: %[[B:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]] %[[B_ACCESS_CHAIN_ID]]

// CHECK: %[[INSERT_ID:[a-zA-Z0-9_]*]] = OpCompositeInsert %[[FLOAT2_TYPE_ID]] %[[B]] %[[UNDEF_ID]] 0
// CHECK: %[[PACKED_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[UINT_TYPE_ID]] %[[EXT_INST]] PackHalf2x16 %[[INSERT_ID]]

// CHECK: %[[INDEX_INTO_UINT:[a-zA-Z0-9_]*]] = OpShiftRightLogical %[[UINT_TYPE_ID]] %[[N]] %[[CONSTANT_1_ID]]
// CHECK: %[[OUT_PTR:[a-zA-Z0-9_]*]] = OpAccessChain %[[UINT_POINTER_TYPE_ID]] %[[ARG0_ID]] %[[CONSTANT_0_ID]] %[[INDEX_INTO_UINT]]
// CHECK: %[[PREV_VALUE:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[OUT_PTR]]

// CHECK: %[[SHIFT_RAW:[a-zA-Z0-9_]*]] = OpShiftLeftLogical %[[UINT_TYPE_ID]] %[[N]] %[[CONSTANT_4_ID]]
// CHECK: %[[SHIFT:[a-zA-Z0-9_]*]] = OpBitwiseAnd %[[UINT_TYPE_ID]] %[[SHIFT_RAW]] %[[CONSTANT_16_ID]]
// CHECK: %[[MASK_BITS_TO_WRITE:[a-zA-Z0-9_]*]] = OpShiftLeftLogical %[[UINT_TYPE_ID]] %[[CONSTANT_65535_ID]] %[[SHIFT]]

// CHECK: %[[MASKED_PREV_VALUE:[a-zA-Z0-9_]*]] = OpBitwiseAnd %[[UINT_TYPE_ID]] %[[PREV_VALUE]] %[[MASK_BITS_TO_WRITE]]
// CHECK: %[[MASKED_NEW_VALUE:[a-zA-Z0-9_]*]] = OpBitwiseAnd %[[UINT_TYPE_ID]] %[[PACKED_ID]] %[[CONSTANT_65535_ID]]
// CHECK: %[[NEW_BITS_TO_WRITE:[a-zA-Z0-9_]*]] = OpShiftLeftLogical %[[UINT_TYPE_ID]] %[[MASKED_NEW_VALUE]] %[[SHIFT]]

// CHECK: %[[VALUE_TO_XOR:[a-zA-Z0-9_]*]] = OpBitwiseXor %[[UINT_TYPE_ID]] %[[MASKED_PREV_VALUE]] %[[NEW_BITS_TO_WRITE]]
// The 64 here is Relaxed consistency on Uniform memory (a.k.a. OpenCL global memory)
// TODO(dneto): Test vstore_half on local memory.
// CHECK: %[[XOR_RESULT:[a-zA-Z0-9_]*]] = OpAtomicXor %[[UINT_TYPE_ID]] %[[OUT_PTR]] %[[CONSTANT_1_ID]] %[[CONSTANT_64_ID]] %[[VALUE_TO_XOR]]

// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global float* b, int n)
{
  global half* a_half = (global half*) a;
  vstore_half(*b, n, (global half *)a);
}
