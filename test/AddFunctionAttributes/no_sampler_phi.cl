// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[sampler:%[a-zA-Z0-9_]+]] = OpTypeSampler
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[sampler]]
// CHECK-NOT: OpPhi [[sampler]]

const sampler_t sampler =
  CLK_NORMALIZED_COORDS_FALSE | \
  CLK_ADDRESS_CLAMP_TO_EDGE |
  CLK_FILTER_NEAREST;

kernel void foo(read_only image2d_t im1, read_only image2d_t im2)
{
  for (int l = 0; l < 30; ++l) {
    float4 s = read_imagef(im1, sampler, (int2)(0,0));
  }

  float4 w = read_imagef(im2, sampler, (int2)(0, 0));
}

