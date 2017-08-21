// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 41
// CHECK: ; Schema: 0
// CHECK-DAG: OpCapability Shader
// CHECK-DAG: OpCapability VariablePointers
// CHECK-NOT: OpCapability StorageImageReadWithoutFormat
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1

// CHECK: OpMemberDecorate %[[ARG2_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG2_STRUCT_TYPE_ID]] Block

// CHECK: OpDecorate %[[ARG3_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 16

// CHECK: OpMemberDecorate %[[ARG3_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG3_STRUCT_TYPE_ID]] Block

// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0

// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG1_ID]] Binding 1
// CHECK: OpDecorate %[[ARG1_ID]] NonWritable

// CHECK: OpDecorate %[[ARG2_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG2_ID]] Binding 2

// CHECK: OpDecorate %[[ARG3_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG3_ID]] Binding 3

// CHECK: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK: %[[SAMPLER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeSampler
// CHECK: %[[ARG0_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer UniformConstant %[[SAMPLER_TYPE_ID]]
// CHECK: %[[READ_ONLY_IMAGE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeImage %[[FLOAT_TYPE_ID]] 2D 0 0 0 1 Unknown
// CHECK: %[[ARG1_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer UniformConstant %[[READ_ONLY_IMAGE_TYPE_ID]]
// CHECK: %[[FLOAT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2
// CHECK: %[[ARG2_STRUCT_TYPE_ID]] = OpTypeStruct %[[FLOAT2_TYPE_ID]]
// CHECK: %[[ARG2_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG2_STRUCT_TYPE_ID]]
// CHECK: %[[FLOAT2_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT2_TYPE_ID]]
// CHECK: %[[FLOAT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK: %[[FLOAT4_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT4_TYPE_ID]]
// CHECK: %[[ARG3_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[FLOAT4_TYPE_ID]]
// CHECK: %[[ARG3_STRUCT_TYPE_ID]] = OpTypeStruct %[[ARG3_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK: %[[ARG3_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG3_STRUCT_TYPE_ID]]
// CHECK: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK: %[[BAR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[FLOAT4_TYPE_ID]] %[[SAMPLER_TYPE_ID]] %[[READ_ONLY_IMAGE_TYPE_ID]] %[[FLOAT2_TYPE_ID]]

// CHECK: %[[SAMPLED_IMAGE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeSampledImage %[[READ_ONLY_IMAGE_TYPE_ID]]

// CHECK: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: %[[FP_CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 0

// CHECK: %[[ARG0_ID]] = OpVariable %[[ARG0_POINTER_TYPE_ID]] UniformConstant
// CHECK: %[[ARG1_ID]] = OpVariable %[[ARG1_POINTER_TYPE_ID]] UniformConstant
// CHECK: %[[ARG2_ID]] = OpVariable %[[ARG2_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG3_ID]] = OpVariable %[[ARG3_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[BAR_ID:[a-zA-Z0-9_]*]] = OpFunction %[[FLOAT4_TYPE_ID]] Pure %[[BAR_TYPE_ID]]
// CHECK: %[[S_ID:[a-zA-Z0-9_]*]] = OpFunctionParameter %[[SAMPLER_TYPE_ID]]
// CHECK: %[[I_ID:[a-zA-Z0-9_]*]] = OpFunctionParameter %[[READ_ONLY_IMAGE_TYPE_ID]]
// CHECK: %[[C_ID:[a-zA-Z0-9_]*]] = OpFunctionParameter %[[FLOAT2_TYPE_ID]]
// CHECK: %[[BAR_LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[SAMPLED_IMAGE_ID:[a-zA-Z0-9_]*]] = OpSampledImage %[[SAMPLED_IMAGE_TYPE_ID]] %[[I_ID]] %[[S_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpImageSampleExplicitLod %[[FLOAT4_TYPE_ID]] %[[SAMPLED_IMAGE_ID]] %[[C_ID]] Lod %[[FP_CONSTANT_0_ID]]
// CHECK: OpReturnValue %[[OP_ID]]
// CHECK: OpFunctionEnd

float4 bar(sampler_t s, read_only image2d_t i, float2 c)
{
  return read_imagef(i, s, c);
}

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[S_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[SAMPLER_TYPE_ID]] %[[ARG0_ID]]
// CHECK: %[[I_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[READ_ONLY_IMAGE_TYPE_ID]] %[[ARG1_ID]]
// CHECK: %[[C_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT2_POINTER_TYPE_ID]] %[[ARG2_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[C_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT2_TYPE_ID]] %[[C_ACCESS_CHAIN_ID]]
// CHECK: %[[A_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT4_POINTER_TYPE_ID]] %[[ARG3_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[CALL_ID:[a-zA-Z0-9_]*]] = OpFunctionCall %[[FLOAT4_TYPE_ID]] %[[BAR_ID]] %[[S_LOAD_ID]] %[[I_LOAD_ID]] %[[C_LOAD_ID]]
// CHECK: OpStore %[[A_ACCESS_CHAIN_ID]] %[[CALL_ID]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(sampler_t s, read_only image2d_t i, float2 c, global float4* a)
{
  *a = bar(s, i, c);
}
