// RUN: clspv -samplermap %S/foo.samplermap %s -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv
//
// RUN: clspv %s -o %t2.spv
// RUN: spirv-dis -o %t2.spvasm %t2.spv
// RUN: FileCheck -check-prefix=NOMAP %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t2.spv

// CHECK: OpDecorate %[[SAMPLER_MAP_ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[SAMPLER_MAP_ARG0_ID]] Binding 0
// CHECK: OpDecorate %[[SAMPLER_MAP_ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[SAMPLER_MAP_ARG1_ID]] Binding 1
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[READ_ONLY_IMAGE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeImage %[[FLOAT_TYPE_ID]] 2D 0 0 0 1 Unknown
// CHECK-DAG: %[[FLOAT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2
// CHECK-DAG: %[[FLOAT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[SAMPLER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeSampler
// CHECK-DAG: %[[SAMPLER_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer UniformConstant %[[SAMPLER_TYPE_ID]]
// CHECK-DAG: %[[SAMPLED_IMAGE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeSampledImage %[[READ_ONLY_IMAGE_TYPE_ID]]
// CHECK-DAG: %[[FP_CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 0
// CHECK: %[[SAMPLER_MAP_ARG0_ID]] = OpVariable %[[SAMPLER_POINTER_TYPE_ID]] UniformConstant
// CHECK: %[[SAMPLER_MAP_ARG1_ID]] = OpVariable %[[SAMPLER_POINTER_TYPE_ID]] UniformConstant
// CHECK: %[[I_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[READ_ONLY_IMAGE_TYPE_ID]]
// CHECK: %[[C_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT2_TYPE_ID]]
// CHECK: OpLabel
// CHECK: %[[ELSE_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[SAMPLER_TYPE_ID]] %[[SAMPLER_MAP_ARG1_ID]]
// CHECK: %[[ELSE_SAMPLED_IMAGE_ID:[a-zA-Z0-9_]*]] = OpSampledImage %[[SAMPLED_IMAGE_TYPE_ID]] %[[I_LOAD_ID]] %[[ELSE_LOAD_ID]]
// CHECK: %[[ELSE_SAMPLE_ID:[a-zA-Z0-9_]*]] = OpImageSampleExplicitLod %[[FLOAT4_TYPE_ID]] %[[ELSE_SAMPLED_IMAGE_ID]] %[[C_LOAD_ID]] Lod %[[FP_CONSTANT_0_ID]]
// CHECK: OpLabel
// CHECK: OpLabel
// CHECK: %[[IF_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[SAMPLER_TYPE_ID]] %[[SAMPLER_MAP_ARG0_ID]]
// CHECK: %[[IF_SAMPLED_IMAGE_ID:[a-zA-Z0-9_]*]] = OpSampledImage %[[SAMPLED_IMAGE_TYPE_ID]] %[[I_LOAD_ID]] %[[IF_LOAD_ID]]
// CHECK: %[[IF_SAMPLE_ID:[a-zA-Z0-9_]*]] = OpImageSampleExplicitLod %[[FLOAT4_TYPE_ID]] %[[IF_SAMPLED_IMAGE_ID]] %[[C_LOAD_ID]] Lod %[[FP_CONSTANT_0_ID]]

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

// NOMAP: OpDecorate [[S0:%[a-zA-Z0-9_]+]] DescriptorSet 0
// NOMAP: OpDecorate [[S0]] Binding 1
// NOMAP: OpDecorate [[S1:%[a-zA-Z0-9_]+]] DescriptorSet 0
// NOMAP: OpDecorate [[S1]] Binding 0
// NOMAP-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// NOMAP-DAG: [[v2float:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 2
// NOMAP-DAG: [[v4float:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 4
// NOMAP-DAG: [[image:%[a-zA-Z0-9_]+]] = OpTypeImage [[float]] 2D 0 0 0 1 Unknown
// NOMAP-DAG: [[sampler:%[a-zA-Z0-9_]+]] = OpTypeSampler
// NOMAP-DAG: [[sampled_image:%[a-zA-Z0-9_]+]] = OpTypeSampledImage [[image]]
// NOMAP-DAG: [[sampler_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer UniformConstant [[sampler]]
// NOMAP-DAG: [[S0]] = OpVariable [[sampler_ptr]] UniformConstant
// NOMAP-DAG: [[S1]] = OpVariable [[sampler_ptr]] UniformConstant
// NOMAP: [[S1_LD:%[a-zA-Z0-9_]+]] = OpLoad [[sampler]] [[S1]]
// NOMAP: [[else_sampled:%[a-zA-Z0-9_]+]] = OpSampledImage [[sampled_image]] {{.*}} [[S1_LD]]
// NOMAP: OpImageSampleExplicitLod [[v4float]] [[else_sampled]]
// NOMAP: [[S0_LD:%[a-zA-Z0-9_]+]] = OpLoad [[sampler]] [[S0]]
// NOMAP: [[then_sampled:%[a-zA-Z0-9_]+]] = OpSampledImage [[sampled_image]] {{.*}} [[S0_LD]]
// NOMAP: OpImageSampleExplicitLod [[v4float]] [[then_sampled]]
