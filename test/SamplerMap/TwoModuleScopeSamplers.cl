// RUN: clspv -samplermap %S/foo.samplermap %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv -samplermap %S/foo.samplermap %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 52
// CHECK: ; Schema: 0
// CHECK-DAG: OpCapability Shader
// CHECK-NOT OpCapability StorageImageReadWithoutFormat
// CHECK-DAG: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1

// CHECK: OpMemberDecorate %[[ARG2_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG2_STRUCT_TYPE_ID]] Block

// CHECK: OpDecorate %[[ARG3_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 16

// CHECK: OpMemberDecorate %[[ARG3_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG3_STRUCT_TYPE_ID]] Block

// CHECK: OpDecorate %[[SAMPLER_MAP_ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[SAMPLER_MAP_ARG0_ID]] Binding 0

// CHECK: OpDecorate %[[SAMPLER_MAP_ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[SAMPLER_MAP_ARG1_ID]] Binding 1

// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 1
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0
// CHECK: OpDecorate %[[ARG0_ID]] NonWritable

// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 1
// CHECK: OpDecorate %[[ARG1_ID]] Binding 1

// CHECK: OpDecorate %[[ARG2_ID:[a-zA-Z0-9_]*]] DescriptorSet 1
// CHECK: OpDecorate %[[ARG2_ID]] Binding 2

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[READ_ONLY_IMAGE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeImage %[[FLOAT_TYPE_ID]] 2D 0 0 0 1 Unknown
// CHECK-DAG: %[[ARG0_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer UniformConstant %[[READ_ONLY_IMAGE_TYPE_ID]]

// CHECK-DAG: %[[FLOAT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2
// CHECK-DAG: %[[ARG2_STRUCT_TYPE_ID]] = OpTypeStruct %[[FLOAT2_TYPE_ID]]
// CHECK-DAG: %[[ARG1_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG2_STRUCT_TYPE_ID]]
// CHECK-DAG: %[[FLOAT2_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT2_TYPE_ID]]

// CHECK-DAG: %[[FLOAT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[FLOAT4_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT4_TYPE_ID]]

// CHECK-DAG: %[[ARG3_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[FLOAT4_TYPE_ID]]
// CHECK-DAG: %[[ARG3_STRUCT_TYPE_ID]] = OpTypeStruct %[[ARG3_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK-DAG: %[[ARG2_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG3_STRUCT_TYPE_ID]]

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK-DAG: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool

// CHECK-DAG: %[[SAMPLER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeSampler
// CHECK-DAG: %[[SAMPLER_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer UniformConstant %[[SAMPLER_TYPE_ID]]

// CHECK-DAG: %[[SAMPLED_IMAGE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeSampledImage %[[READ_ONLY_IMAGE_TYPE_ID]]

// CHECK-DAG: %[[FP_CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: %[[UNDEF_ID:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT4_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_FALSE_ID:[a-zA-Z0-9_]*]] = OpConstantFalse %[[BOOL_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_TRUE_ID:[a-zA-Z0-9_]*]] = OpConstantTrue %[[BOOL_TYPE_ID]]

// CHECK: %[[SAMPLER_MAP_ARG0_ID]] = OpVariable %[[SAMPLER_POINTER_TYPE_ID]] UniformConstant
// CHECK: %[[SAMPLER_MAP_ARG1_ID]] = OpVariable %[[SAMPLER_POINTER_TYPE_ID]] UniformConstant
// CHECK: %[[ARG0_ID]] = OpVariable %[[ARG0_POINTER_TYPE_ID]] UniformConstant
// CHECK: %[[ARG1_ID]] = OpVariable %[[ARG1_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG2_ID]] = OpVariable %[[ARG2_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[I_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[READ_ONLY_IMAGE_TYPE_ID]] %[[ARG0_ID]]
// CHECK: %[[C_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT2_POINTER_TYPE_ID]] %[[ARG1_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[C_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT2_TYPE_ID]] %[[C_ACCESS_CHAIN_ID]]
// CHECK: %[[A_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT4_POINTER_TYPE_ID]] %[[ARG2_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[C_X_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[C_LOAD_ID]] 0
// CHECK: %[[CMP_ID:[a-zA-Z0-9_]*]] = OpFOrdLessThan %[[BOOL_TYPE_ID]] %[[C_X_ID]] %[[FP_CONSTANT_0_ID]]
// CHECK: %[[NOT_CMP_ID:[a-zA-Z0-9_]*]] = OpLogicalNot %[[BOOL_TYPE_ID]] %[[CMP_ID]]
// CHECK: OpSelectionMerge %[[MERGE1_ID:[a-zA-Z0-9_]*]] None
// CHECK: OpBranchConditional %[[NOT_CMP_ID]] %[[ELSE_ID:[a-zA-Z0-9_]*]] %[[MERGE1_ID]]

// CHECK: %[[ELSE_ID]] = OpLabel
// CHECK: %[[ELSE_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[SAMPLER_TYPE_ID]] %[[SAMPLER_MAP_ARG1_ID]]
// CHECK: %[[ELSE_SAMPLED_IMAGE_ID:[a-zA-Z0-9_]*]] = OpSampledImage %[[SAMPLED_IMAGE_TYPE_ID]] %[[I_LOAD_ID]] %[[ELSE_LOAD_ID]]
// CHECK: %[[ELSE_SAMPLE_ID:[a-zA-Z0-9_]*]] = OpImageSampleExplicitLod %[[FLOAT4_TYPE_ID]] %[[ELSE_SAMPLED_IMAGE_ID]] %[[C_LOAD_ID]] Lod %[[FP_CONSTANT_0_ID]]
// CHECK: OpBranch %[[MERGE1_ID]]

// CHECK: %[[MERGE1_ID]] = OpLabel
// CHECK: %[[CMP_PHI_ID:[a-zA-Z0-9_]*]] = OpPhi %[[BOOL_TYPE_ID]] %[[CONSTANT_FALSE_ID]] %[[ELSE_ID]] %[[CONSTANT_TRUE_ID]] %[[LABEL_ID]]
// CHECK: %[[TMP_SAMPLE_ID:[a-zA-Z0-9_]*]] = OpPhi %[[FLOAT4_TYPE_ID]] %[[ELSE_SAMPLE_ID]] %[[ELSE_ID]] %[[UNDEF_ID]] %[[LABEL_ID]]
// CHECK: OpSelectionMerge %[[MERGE2_ID:[a-zA-Z0-9_]*]] None
// CHECK: OpBranchConditional %[[CMP_PHI_ID]] %[[IF_ID:[a-zA-Z0-9_]*]] %[[MERGE2_ID]]

// CHECK: %[[MERGE2_ID]] = OpLabel
// CHECK: %[[SAMPLE_ID:[a-zA-Z0-9_]*]] = OpPhi %[[FLOAT4_TYPE_ID]] %[[TMP_SAMPLE_ID]] %[[MERGE1_ID]] %[[IF_SAMPLE_ID:[a-zA-Z0-9_]*]] %[[IF_ID]]
// CHECK: OpStore %[[A_ACCESS_CHAIN_ID]] %[[SAMPLE_ID]]
// CHECK: OpReturn

// CHECK: %[[IF_ID]] = OpLabel
// CHECK: %[[IF_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[SAMPLER_TYPE_ID]] %[[SAMPLER_MAP_ARG0_ID]]
// CHECK: %[[IF_SAMPLED_IMAGE_ID:[a-zA-Z0-9_]*]] = OpSampledImage %[[SAMPLED_IMAGE_TYPE_ID]] %[[I_LOAD_ID]] %[[IF_LOAD_ID]]
// CHECK: %[[IF_SAMPLE_ID]] = OpImageSampleExplicitLod %[[FLOAT4_TYPE_ID]] %[[IF_SAMPLED_IMAGE_ID]] %[[C_LOAD_ID]] Lod %[[FP_CONSTANT_0_ID]]
// CHECK: OpBranch %[[MERGE2_ID]]
// CHECK: OpFunctionEnd

constant sampler_t s0 = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;
constant sampler_t s1 = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(read_only image2d_t i, float2 c, global float4* a)
{
  if (c.x < 0.0f) {
    *a = read_imagef(i, s0, c);
  } else {
    *a = read_imagef(i, s1, c);
  }
}
