// RUN: clspv %s -o %t.spv -descriptormap=%t.map
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: FileCheck -check-prefix MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

const sampler_t s0 =
CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_REPEAT | CLK_FILTER_NEAREST;

const sampler_t s1 =
CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_REPEAT | CLK_FILTER_NEAREST;

kernel void foo(read_only image2d_t i1, read_only image2d_t i2, global float4* f_out, global int4* i_out) {
  *f_out = read_imagef(i1, s0, (float2)(0.0));
  *i_out = read_imagei(i2, s1, (float2)(0.0));
}

//      MAP: sampler,23,samplerExpr,"CLK_NORMALIZED_COORDS_TRUE|CLK_ADDRESS_REPEAT|CLK_FILTER_NEAREST",descriptorSet,0,binding,1
// MAP-NEXT: sampler,22,samplerExpr,"CLK_NORMALIZED_COORDS_FALSE|CLK_ADDRESS_REPEAT|CLK_FILTER_NEAREST",descriptorSet,0,binding,0


// CHECK: OpDecorate [[S0:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[S0]] Binding 1
// CHECK: OpDecorate [[S1:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[S1]] Binding 0
// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[v4float:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 1
// CHECK-DAG: [[v4int:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 4
// CHECK-DAG: [[sampler:%[a-zA-Z0-9_]+]] = OpTypeSampler
// CHECK-DAG: [[float_image:%[a-zA-Z0-9_]+]] = OpTypeImage [[float]] 2D 0 0 0 1 Unknown
// CHECK-DAG: [[int_image:%[a-zA-Z0-9_]+]] = OpTypeImage [[int]] 2D 0 0 0 1 Unknown
// CHECK-DAG: [[float_sampled_image:%[a-zA-Z0-9_]+]] = OpTypeSampledImage [[float_image]]
// CHECK-DAG: [[int_sampled_image:%[a-zA-Z0-9_]+]] = OpTypeSampledImage [[int_image]]
// CHECK-DAG: [[ld_s0:%[a-zA-Z0-9_]+]] = OpLoad [[sampler]] [[S0]]
// CHECK-DAG: [[ld_s1:%[a-zA-Z0-9_]+]] = OpLoad [[sampler]] [[S1]]
// CHECK-DAG: [[ld_float_image:%[a-zA-Z0-9_]+]] = OpLoad [[float_image]]
// CHECK-DAG: [[ld_int_image:%[a-zA-Z0-9_]+]] = OpLoad [[int_image]]
// CHECK-DAG: OpSampledImage [[float_sampled_image]] [[ld_float_image]] [[ld_s0]]
// CHECK-DAG: OpSampledImage [[int_sampled_image]] [[ld_int_image]] [[ld_s1]]
