// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// 0x1 | 0x4 | 0x10 = 21
static const sampler_t s1 = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP | CLK_FILTER_NEAREST;
// 0x0 | 0x4 | 0x10 = 20
static const sampler_t s2 = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP | CLK_FILTER_NEAREST;
// 0x1 | 0x2 | 0x10 = 19
static const sampler_t s3 = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;
// 0x1 | 0x4 | 0x20 = 37
static const sampler_t s4 = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP | CLK_FILTER_LINEAR;

kernel void foo(global float4* data, read_only image2d_t im) {
  data[0] = read_imagef(im, s1, (float2)(0.0f, 0.0f));
  data[1] = read_imagef(im, s2, (float2)(0.0f, 0.0f));
  data[2] = read_imagef(im, s3, (float2)(0.0f, 0.0f));
  data[3] = read_imagef(im, s4, (float2)(0.0f, 0.0f));
}

// CHECK: [[import:%[a-zA-Z0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"
// CHECK-DAG: OpDecorate [[s1:%[a-zA-Z0-9_]+]] Binding 3
// CHECK-DAG: OpDecorate [[s1]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[s2:%[a-zA-Z0-9_]+]] Binding 2
// CHECK-DAG: OpDecorate [[s2]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[s3:%[a-zA-Z0-9_]+]] Binding 1
// CHECK-DAG: OpDecorate [[s3]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[s4:%[a-zA-Z0-9_]+]] Binding 0
// CHECK-DAG: OpDecorate [[s4]] DescriptorSet 0
// CHECK-DAG: [[void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_19:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 19
// CHECK-DAG: [[uint_20:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 20
// CHECK-DAG: [[uint_21:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 21
// CHECK-DAG: [[uint_37:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 37
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_2:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 2
// CHECK-DAG: [[uint_3:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 3
// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[float2_0:%[a-zA-Z0-9_]+]] = OpConstantNull [[float2]]
// CHECK-DAG: [[sampler:%[a-zA-Z0-9_]+]] = OpTypeSampler
//
// CHECK: [[gep0:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]]
// CHECK: [[s1_ld:%[a-zA-Z0-9_]+]] = OpLoad [[sampler]] [[s1]]
// CHECK: [[s1_combined:%[a-zA-Z0-9_]+]] = OpSampledImage {{.*}} {{.*}} [[s1_ld]]
// CHECK: [[read:%[a-zA-Z0-9_]+]] = OpImageSampleExplicitLod {{.*}} [[s1_combined]]
// CHECK: OpStore [[gep0]] [[read]]
//
// CHECK: [[s2_ld:%[a-zA-Z0-9_]+]] = OpLoad [[sampler]] [[s2]]
// CHECK: [[s2_combined:%[a-zA-Z0-9_]+]] = OpSampledImage {{.*}} {{.*}} [[s2_ld]]
// CHECK: [[read:%[a-zA-Z0-9_]+]] = OpImageSampleExplicitLod {{.*}} [[s2_combined]]
// CHECK: [[gep1:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_1]]
// CHECK: OpStore [[gep1]] [[read]]
//
// CHECK: [[s3_ld:%[a-zA-Z0-9_]+]] = OpLoad [[sampler]] [[s3]]
// CHECK: [[s3_combined:%[a-zA-Z0-9_]+]] = OpSampledImage {{.*}} {{.*}} [[s3_ld]]
// CHECK: [[read:%[a-zA-Z0-9_]+]] = OpImageSampleExplicitLod {{.*}} [[s3_combined]]
// CHECK: [[gep2:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_2]]
// CHECK: OpStore [[gep2]] [[read]]
//
// CHECK: [[s4_ld:%[a-zA-Z0-9_]+]] = OpLoad [[sampler]] [[s4]]
// CHECK: [[s4_combined:%[a-zA-Z0-9_]+]] = OpSampledImage {{.*}} {{.*}} [[s4_ld]]
// CHECK: [[read:%[a-zA-Z0-9_]+]] = OpImageSampleExplicitLod {{.*}} [[s4_combined]]
// CHECK: [[gep3:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_3]]
// CHECK: OpStore [[gep3]] [[read]]
//
// CHECK-DAG: OpExtInst [[void]] [[import]] LiteralSampler [[uint_0]] [[uint_0]] [[uint_37]]
// CHECK-DAG: OpExtInst [[void]] [[import]] LiteralSampler [[uint_0]] [[uint_1]] [[uint_19]]
// CHECK-DAG: OpExtInst [[void]] [[import]] LiteralSampler [[uint_0]] [[uint_2]] [[uint_20]]
// CHECK-DAG: OpExtInst [[void]] [[import]] LiteralSampler [[uint_0]] [[uint_3]] [[uint_21]]

