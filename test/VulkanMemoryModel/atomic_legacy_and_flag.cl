// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.3 --cl-std=CL2.0 -inline-entry-points -hack-atomic-flag-barrier
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

// CHECK-DAG: OpCapability VulkanMemoryModel
// CHECK-DAG: OpCapability VulkanMemoryModelDeviceScope
// CHECK: OpMemoryModel Logical Vulkan

// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0{{$}}
// CHECK-DAG: [[dev:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1{{$}}

// Acquire | UniformMemory | MakeVisible = 16450
// CHECK-DAG: [[acq_uni:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 16450{{$}}
// Release | UniformMemory | MakeAvailable = 8260
// CHECK-DAG: [[rel_uni:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 8260{{$}}
// AcquireRelease | UniformMemory | MakeAvailable | MakeVisible = 24648
// CHECK-DAG: [[acqrel_uni:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 24648{{$}}

// Legacy OpenCL 1.x atomics:
// CHECK: OpAtomicIAdd [[uint]] {{.*}} [[dev]] [[acqrel_uni]]
// CHECK: OpAtomicIIncrement [[uint]] {{.*}} [[dev]] [[acqrel_uni]]
// CHECK: OpAtomicCompareExchange [[uint]] {{.*}} [[dev]] [[acqrel_uni]] [[acq_uni]]

// Atomic flag with -hack-atomic-flag-barrier:
// CHECK: OpMemoryBarrier [[dev]] [[rel_uni]]
// CHECK-NEXT: OpAtomicExchange [[uint]] {{.*}} [[dev]] [[acqrel_uni]] [[dev]]
// CHECK-NEXT: OpMemoryBarrier [[dev]] [[acq_uni]]
// CHECK: OpMemoryBarrier [[dev]] [[rel_uni]]
// CHECK-NEXT: OpAtomicStore {{.*}} [[dev]] [[rel_uni]] [[uint_0]]

kernel void test_legacy_and_flag(global volatile int *p, global atomic_flag *flag, global int *out) {
  int r = atomic_add(p, 5);
  r += atomic_inc(p);
  r += atomic_cmpxchg(p, 6, 10);
  if (atomic_flag_test_and_set(flag)) {
    atomic_flag_clear(flag);
  }
  *out = r;
}
