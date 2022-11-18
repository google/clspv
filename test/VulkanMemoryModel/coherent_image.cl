// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.5 -cl-std=CL2.0 -inline-entry-points
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.2spv1.5 %t.spv

kernel void foo(read_write image1d_t im) {
  uint4 x = read_imageui(im, 0);
  barrier(CLK_GLOBAL_MEM_FENCE);
  write_imageui(im, 0, x);
}

// CHECK-NOT: OpDecorate {{.*}} Coherent
// CHECK: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
// CHECK: [[DEVICE_SCOPE:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 1
// CHECK: {{.*}} = OpImageRead {{.*}} {{.*}} {{.*}} MakeTexelVisible|NonPrivateTexel|ZeroExtend [[DEVICE_SCOPE]]
// CHECK: OpImageWrite {{.*}} {{.*}} {{.*}} MakeTexelAvailable|NonPrivateTexel|ZeroExtend [[DEVICE_SCOPE]]
