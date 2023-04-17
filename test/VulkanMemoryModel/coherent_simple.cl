// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.5
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.2spv1.5 %t.spv

kernel void foo(global int* data) {
  int x = data[0];
  barrier(CLK_GLOBAL_MEM_FENCE);
  data[1] = x;
}

// CHECK-NOT: OpDecorate {{.*}} Coherent
// CHECK: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
// CHECK: [[DEVICE_SCOPE:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 1
// CHECK: {{.*}} = OpLoad [[uint]] {{.*}} MakePointerVisible|NonPrivatePointer [[DEVICE_SCOPE]]
// CHECK: OpStore {{.*}} {{.*}} MakePointerAvailable|NonPrivatePointer [[DEVICE_SCOPE]]
