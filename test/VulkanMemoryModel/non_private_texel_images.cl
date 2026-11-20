// RUN: clspv %target %s -o %t.spv -vulkan-memory-model --cl-std=CL2.0 --inline-entry-points -spv-version=1.3
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefixes=CHECK,SPV13 < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

// RUN: clspv %target %s -o %t.spv -vulkan-memory-model --cl-std=CL2.0 --inline-entry-points -spv-version=1.4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefixes=CHECK,SPV14 < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

// CHECK: OpCapability VulkanMemoryModel
// CHECK: OpMemoryModel Logical Vulkan
// CHECK-NOT: OpDecorate {{.*}} Coherent

// Sampled image read uses OpImageSampleExplicitLod (must NOT have NonPrivateTexel)
// CHECK: OpImageSampleExplicitLod {{.*}} Lod

// Storage image read uses OpImageRead with NonPrivateTexel
// SPV13: OpImageRead {{.*}} NonPrivateTexel{{$}}
// SPV14: OpImageRead {{.*}} NonPrivateTexel|ZeroExtend{{$}}

// Storage image write uses OpImageWrite with NonPrivateTexel
// SPV13: OpImageWrite {{.*}} NonPrivateTexel{{$}}
// SPV14: OpImageWrite {{.*}} NonPrivateTexel|ZeroExtend{{$}}

kernel void test_images(read_only image2d_t sampled_img,
                        sampler_t s,
                        read_write image2d_t storage_img,
                        int2 coord,
                        global uint4 *out) {
  float4 v = read_imagef(sampled_img, s, convert_float2(coord));
  uint4 u = read_imageui(storage_img, coord);
  barrier(CLK_IMAGE_MEM_FENCE);
  write_imageui(storage_img, coord, u + convert_uint4(v));
  *out = u;
}
