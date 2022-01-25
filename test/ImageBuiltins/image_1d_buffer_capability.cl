// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-NOT: OpCapability Sampled1D
// CHECK-NOT: OpCapability Image1D
// CHECK: OpCapability ImageBuffer
// CHECK-NOT: OpCapability Image1D
// CHECK-NOT: OpCapability Sampled1D

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(write_only image1d_buffer_t i, int c, float4 a)
{
  write_imagef(i, c, a);
}

