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

// 0 = Relaxed
// CHECK-DAG: [[relaxed:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0{{$}}

// Uniform (global):
// Acquire | UniformMemory | MakeVisible = 2 | 64 | 16384 = 16450
// CHECK-DAG: [[acq_uni:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 16450{{$}}
// Release | UniformMemory | MakeAvailable = 4 | 64 | 8192 = 8260
// CHECK-DAG: [[rel_uni:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 8260{{$}}
// AcquireRelease | UniformMemory | MakeAvailable | MakeVisible = 8 | 64 | 8192 | 16384 = 24648
// CHECK-DAG: [[acqrel_uni:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 24648{{$}}

// Workgroup (local):
// Acquire | WorkgroupMemory | MakeVisible = 2 | 256 | 16384 = 16642
// CHECK-DAG: [[acq_wg:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 16642{{$}}
// Release | WorkgroupMemory | MakeAvailable = 4 | 256 | 8192 = 8452
// CHECK-DAG: [[rel_wg:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 8452{{$}}
// AcquireRelease | WorkgroupMemory | MakeAvailable | MakeVisible = 8 | 256 | 8192 | 16384 = 24840
// CHECK-DAG: [[acqrel_wg:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 24840{{$}}

// CHECK: OpAtomicLoad [[uint]] {{.*}} [[dev]] [[relaxed]]
// CHECK: OpAtomicLoad [[uint]] {{.*}} [[dev]] [[acq_uni]]
// CHECK: OpAtomicLoad [[uint]] {{.*}} [[dev]] [[acq_uni]]
// CHECK: OpAtomicStore {{.*}} [[dev]] [[relaxed]]
// CHECK: OpAtomicStore {{.*}} [[dev]] [[rel_uni]]
// CHECK: OpAtomicStore {{.*}} [[dev]] [[rel_uni]]
// CHECK: OpAtomicIAdd [[uint]] {{.*}} [[dev]] [[relaxed]]
// CHECK: OpAtomicIAdd [[uint]] {{.*}} [[dev]] [[acq_uni]]
// CHECK: OpAtomicIAdd [[uint]] {{.*}} [[dev]] [[rel_uni]]
// CHECK: OpAtomicIAdd [[uint]] {{.*}} [[dev]] [[acqrel_uni]]
// CHECK: OpAtomicIAdd [[uint]] {{.*}} [[dev]] [[acqrel_uni]]

// CHECK: OpAtomicLoad [[uint]] {{.*}} [[wg]] [[relaxed]]
// CHECK: OpAtomicLoad [[uint]] {{.*}} [[wg]] [[acq_wg]]
// CHECK: OpAtomicStore {{.*}} [[wg]] [[rel_wg]]
// CHECK: OpAtomicExchange [[uint]] {{.*}} [[wg]] [[acqrel_wg]]

kernel void test_explicit_atomics(global atomic_int *ga, local atomic_int *la, global int *out) {
  int r = 0;
  r += atomic_load_explicit(ga, memory_order_relaxed, memory_scope_device);
  r += atomic_load_explicit(ga, memory_order_acquire, memory_scope_device);
  r += atomic_load_explicit(ga, memory_order_seq_cst, memory_scope_device);

  atomic_store_explicit(ga, r, memory_order_relaxed, memory_scope_device);
  atomic_store_explicit(ga, r, memory_order_release, memory_scope_device);
  atomic_store_explicit(ga, r, memory_order_seq_cst, memory_scope_device);

  r += atomic_fetch_add_explicit(ga, 1, memory_order_relaxed, memory_scope_device);
  r += atomic_fetch_add_explicit(ga, 1, memory_order_acquire, memory_scope_device);
  r += atomic_fetch_add_explicit(ga, 1, memory_order_release, memory_scope_device);
  r += atomic_fetch_add_explicit(ga, 1, memory_order_acq_rel, memory_scope_device);
  r += atomic_fetch_add_explicit(ga, 1, memory_order_seq_cst, memory_scope_device);

  r += atomic_load_explicit(la, memory_order_relaxed, memory_scope_work_group);
  r += atomic_load_explicit(la, memory_order_acquire, memory_scope_work_group);
  atomic_store_explicit(la, r, memory_order_release, memory_scope_work_group);
  r += atomic_exchange_explicit(la, r, memory_order_acq_rel, memory_scope_work_group);

  *out = r;
}
