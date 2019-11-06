// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-NOT: OpCapability StorageImageReadWithoutFormat
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[SAMPLER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeSampler
// CHECK-DAG: %[[READ_ONLY_IMAGE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeImage %[[FLOAT_TYPE_ID]] 3D 0 0 0 1 Unknown
// CHECK-DAG: %[[FLOAT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[SAMPLED_IMAGE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeSampledImage %[[READ_ONLY_IMAGE_TYPE_ID]]
// CHECK-DAG: %[[FP_CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 0
// CHECK: %[[S_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[SAMPLER_TYPE_ID]]
// CHECK: %[[I_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[READ_ONLY_IMAGE_TYPE_ID]]
// CHECK: %[[C_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT4_TYPE_ID]]
// CHECK: %[[SAMPLED_IMAGE_ID:[a-zA-Z0-9_]*]] = OpSampledImage %[[SAMPLED_IMAGE_TYPE_ID]] %[[I_LOAD_ID]] %[[S_LOAD_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpImageSampleExplicitLod %[[FLOAT4_TYPE_ID]] %[[SAMPLED_IMAGE_ID]] %[[C_LOAD_ID]] Lod %[[FP_CONSTANT_0_ID]]
// CHECK: OpStore {{.*}} %[[OP_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(sampler_t s, read_only image3d_t i, float4 c, global float4* a)
{
  *a = read_imagef(i, s, c);
}
