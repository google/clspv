// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[sampler:%[a-zA-Z0-9_]+]] = OpTypeSampler
// CHECK-NOT: OpPhi [[sampler]]

static const sampler_t sampler =
  CLK_NORMALIZED_COORDS_FALSE |
  CLK_ADDRESS_CLAMP_TO_EDGE |
  CLK_FILTER_NEAREST;

kernel void foo(read_only image2d_t imageA, int itrs) {
  int x = (int)get_global_id(0);
  int y = (int)get_global_id(1);
  for (int i = 0; i < itrs; ++i) {
    int2 coords = (int2)(x, y);
    float4 valueA = read_imagef(imageA, sampler, coords);
  }
  float4 valueB = read_imagef(imageA, sampler, (int2)(0, 0));
}
