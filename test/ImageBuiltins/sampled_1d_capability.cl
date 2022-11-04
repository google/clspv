// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(sampler_t s, read_only image1d_t i, float c, global float4* a)
{
  *a = read_imagef(i, s, c);
}

// CHECK-NOT OpCapability Image1D
// CHECK: OpCapability Sampled1D
// CHECK-NOT OpCapability Image1D
