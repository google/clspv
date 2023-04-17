// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.5
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.2spv1.5 %t.spv

__attribute__((noinline))
int bar(global int* x) { return x[0]; }

kernel void foo1(global int* data) {
  int x = bar(data);
  barrier(CLK_GLOBAL_MEM_FENCE);
  data[1] = x;
}

kernel void foo2(global int* x, global int* y) {
  int z = bar(x);
  barrier(CLK_GLOBAL_MEM_FENCE);
  y[0] = z;
}

// CHECK-NOT: OpDecorate {{.*}} Coherent
// CHECK: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
// CHECK: [[DEVICE_SCOPE:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 1
// CHECK: OpStore {{.*}} {{.*}} MakePointerAvailable|NonPrivatePointer [[DEVICE_SCOPE]]
