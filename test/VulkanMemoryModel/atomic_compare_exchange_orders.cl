// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.3 --cl-std=CL2.0 --inline-entry-points
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

// CHECK-DAG: OpCapability VulkanMemoryModel
// CHECK-DAG: OpCapability VulkanMemoryModelDeviceScope
// CHECK: OpMemoryModel Logical Vulkan

// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[dev:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1{{$}}
// CHECK-DAG: [[wg:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 2{{$}}
// CHECK-DAG: [[val:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 7{{$}}
// CHECK-DAG: [[relaxed:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0{{$}}

// Uniform (global):
// Acquire | UniformMemory | MakeVisible = 16450
// CHECK-DAG: [[acq_uni:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 16450{{$}}
// Release | UniformMemory | MakeAvailable = 8260
// CHECK-DAG: [[rel_uni:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 8260{{$}}
// AcquireRelease | UniformMemory | MakeAvailable | MakeVisible = 24648
// CHECK-DAG: [[acqrel_uni:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 24648{{$}}

// Workgroup (local):
// Acquire | WorkgroupMemory | MakeVisible = 16642
// CHECK-DAG: [[acq_wg:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 16642{{$}}
// Release | WorkgroupMemory | MakeAvailable = 8452
// CHECK-DAG: [[rel_wg:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 8452{{$}}
// AcquireRelease | WorkgroupMemory | MakeAvailable | MakeVisible = 24840
// CHECK-DAG: [[acqrel_wg:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 24840{{$}}

// Default (seq_cst, seq_cst) -> (AcqRel|MakeAvailable|MakeVisible, Acq|MakeVisible)
// CHECK: OpAtomicCompareExchange [[uint]] {{.*}} [[dev]] [[acqrel_uni]] [[acq_uni]] [[val]]
// (release, relaxed) -> Equal stays Release|MakeAvailable, Unequal is Relaxed
// CHECK: OpAtomicCompareExchange [[uint]] {{.*}} [[dev]] [[rel_uni]] [[relaxed]] [[val]]
// (release, acquire) -> Equal promoted to AcqRel|MakeAvailable|MakeVisible so Equal also has MakeVisible (VUID-10878)
// CHECK: OpAtomicCompareExchange [[uint]] {{.*}} [[dev]] [[acqrel_uni]] [[acq_uni]] [[val]]
// (acquire, acquire) -> Both Acq|MakeVisible
// CHECK: OpAtomicCompareExchange [[uint]] {{.*}} [[dev]] [[acq_uni]] [[acq_uni]] [[val]]
// (relaxed, relaxed) -> Both Relaxed
// CHECK: OpAtomicCompareExchange [[uint]] {{.*}} [[dev]] [[relaxed]] [[relaxed]] [[val]]

// Workgroup:
// (release, relaxed)
// CHECK: OpAtomicCompareExchange [[uint]] {{.*}} [[wg]] [[rel_wg]] [[relaxed]] [[val]]
// (release, acquire) -> Equal promoted to AcqRel|WorkgroupMemory|MakeAvailable|MakeVisible
// CHECK: OpAtomicCompareExchange [[uint]] {{.*}} [[wg]] [[acqrel_wg]] [[acq_wg]] [[val]]

kernel void test_cmpxchg(global bool *out, global atomic_int *ga, local atomic_int *la) {
  int expected = 0;
  *out = atomic_compare_exchange_strong(ga, &expected, 7);
  *out = atomic_compare_exchange_strong_explicit(ga, &expected, 7, memory_order_release, memory_order_relaxed, memory_scope_device);
  *out = atomic_compare_exchange_strong_explicit(ga, &expected, 7, memory_order_release, memory_order_acquire, memory_scope_device);
  *out = atomic_compare_exchange_strong_explicit(ga, &expected, 7, memory_order_acquire, memory_order_acquire, memory_scope_device);
  *out = atomic_compare_exchange_strong_explicit(ga, &expected, 7, memory_order_relaxed, memory_order_relaxed, memory_scope_device);

  *out = atomic_compare_exchange_weak_explicit(la, &expected, 7, memory_order_release, memory_order_relaxed, memory_scope_work_group);
  *out = atomic_compare_exchange_weak_explicit(la, &expected, 7, memory_order_release, memory_order_acquire, memory_scope_work_group);
}
