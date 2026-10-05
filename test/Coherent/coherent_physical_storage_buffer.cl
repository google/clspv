// RUN: clspv %s -o %t.spv -arch=spirv64 -physical-storage-buffers
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env vulkan1.2
// RUN: FileCheck %s < %t.spvasm

// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[ptr_uint:%[a-zA-Z0-9_]+]] = OpTypePointer PhysicalStorageBuffer [[uint]]
// CHECK: [[ro_ld:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] {{.*}} Aligned 4
// CHECK: [[rw_ld:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] {{.*}} Volatile|Aligned 4
// CHECK: OpControlBarrier
// CHECK: OpStore {{.*}} Volatile|Aligned 4
// CHECK: OpStore {{.*}} [[ro_ld]] Aligned 4

kernel void foo(global int *rw, global int *ro, global int *wo) {
  int a = ro[0];
  int b = rw[0];
  barrier(CLK_GLOBAL_MEM_FENCE);
  rw[1] = b;
  wo[0] = a;
}
