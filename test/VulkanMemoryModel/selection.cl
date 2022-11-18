// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.5
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.2spv1.5 %t.spv

// Both x's should be coherent. y should not be coherent because it is not read.
__attribute__((noinline))
void bar(global int* x, int y) { *x = y; }

kernel void foo(global int* x, global int* y, int c) {
  int z = x[0];
  barrier(CLK_GLOBAL_MEM_FENCE);
  global int* ptr = c ? x : y;
  bar(ptr + 1, z);
}

// CHECK-NOT: OpDecorate {{.*}} Coherent
// CHECK: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
// CHECK: [[DEVICE_SCOPE:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 1
// CHECK: OpStore {{.*}} {{.*}} MakePointerAvailable|NonPrivatePointer [[DEVICE_SCOPE]]
// CHECK: {{.*}} = OpLoad [[uint]] {{.*}} MakePointerVisible|NonPrivatePointer [[DEVICE_SCOPE]]
