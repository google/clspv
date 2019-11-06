// RUN: clspv -samplermap %S/foo.samplermap %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[READ_ONLY_IMAGE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeImage %[[FLOAT_TYPE_ID]] 2D 0 0 0 1 Unknown
// CHECK-DAG: %[[FLOAT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2
// CHECK-DAG: %[[FLOAT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[SAMPLER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeSampler
// CHECK-DAG: %[[SAMPLED_IMAGE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeSampledImage %[[READ_ONLY_IMAGE_TYPE_ID]]
// CHECK-DAG: %[[FP_CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 0
// CHECK: %[[I_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[READ_ONLY_IMAGE_TYPE_ID]]
// CHECK: %[[C_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT2_TYPE_ID]]
// CHECK: %[[S_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[SAMPLER_TYPE_ID]]
// CHECK: %[[SAMPLED_IMAGE_ID:[a-zA-Z0-9_]*]] = OpSampledImage %[[SAMPLED_IMAGE_TYPE_ID]] %[[I_LOAD_ID]] %[[S_LOAD_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpImageSampleExplicitLod %[[FLOAT4_TYPE_ID]] %[[SAMPLED_IMAGE_ID]] %[[C_LOAD_ID]] Lod %[[FP_CONSTANT_0_ID]]
// CHECK: OpStore {{.*}} %[[OP_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(read_only image2d_t i, float2 c, global float4* a)
{
  sampler_t s = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;
  *a = read_imagef(i, s, c);
}
