// RUN: clspv %s -o %t.spv -arch=spirv64 -physical-storage-buffers -hack-psb-volatile-as-atomic
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env vulkan1.2
// RUN: FileCheck %s < %t.spvasm

// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK: [[ro_ld:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] {{.*}} Aligned 4
// CHECK: [[rw_ld:%[a-zA-Z0-9_]+]] = OpAtomicLoad [[uint]] {{.*}} [[uint_1]] [[uint_0]]
// CHECK: OpControlBarrier
// CHECK: OpAtomicStore {{.*}} [[uint_1]] [[uint_0]] [[rw_ld]]
// CHECK: OpStore {{.*}} [[ro_ld]] Aligned 4

kernel void foo(global int *rw, global int *ro, global int *wo) {
  int a = ro[0];
  int b = rw[0];
  barrier(CLK_GLOBAL_MEM_FENCE);
  rw[1] = b;
  wo[0] = a;
}
