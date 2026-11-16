// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.3 --cl-std=CL3.0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

// CHECK-DAG: OpCapability VulkanMemoryModel
// CHECK-DAG: OpCapability VulkanMemoryModelDeviceScope
// CHECK: OpMemoryModel Logical Vulkan

// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[dev:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1{{$}}
// CHECK-DAG: [[wg:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 2{{$}}
// CHECK-DAG: [[sg:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 3{{$}}

// Acquire | UniformMemory | MakeVisible = 2 | 64 | 16384 = 16450
// CHECK-DAG: [[acq_uni:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 16450{{$}}
// Release | UniformMemory | MakeAvailable = 4 | 64 | 8192 = 8260
// CHECK-DAG: [[rel_uni:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 8260{{$}}
// AcquireRelease | UniformMemory | MakeAvailable | MakeVisible = 8 | 64 | 8192 | 16384 = 24648
// CHECK-DAG: [[acqrel_uni:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 24648{{$}}
// AcquireRelease | WorkgroupMemory | MakeAvailable | MakeVisible = 8 | 256 | 8192 | 16384 = 24840
// CHECK-DAG: [[acqrel_wg:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 24840{{$}}
// AcquireRelease | UniformMemory | WorkgroupMemory | ImageMemory | MakeAvailable | MakeVisible = 8 | 64 | 256 | 2048 | 8192 | 16384 = 26952
// CHECK-DAG: [[acqrel_all:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 26952{{$}}

// CHECK: OpControlBarrier [[wg]] [[wg]] [[acqrel_wg]]
// CHECK: OpControlBarrier [[wg]] [[dev]] [[acqrel_uni]]
// CHECK: OpControlBarrier [[sg]] [[sg]] [[acqrel_wg]]
// CHECK: OpMemoryBarrier [[wg]] [[acqrel_uni]]
// CHECK: OpMemoryBarrier [[wg]] [[acq_uni]]
// CHECK: OpMemoryBarrier [[wg]] [[rel_uni]]
// CHECK: OpMemoryBarrier [[dev]] [[acqrel_all]]

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

kernel void test_sync() {
  work_group_barrier(CLK_LOCAL_MEM_FENCE);
  work_group_barrier(CLK_GLOBAL_MEM_FENCE, memory_scope_device);
  sub_group_barrier(CLK_LOCAL_MEM_FENCE);
  mem_fence(CLK_GLOBAL_MEM_FENCE);
  read_mem_fence(CLK_GLOBAL_MEM_FENCE);
  write_mem_fence(CLK_GLOBAL_MEM_FENCE);
  atomic_work_item_fence(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE | CLK_IMAGE_MEM_FENCE,
                         memory_order_acq_rel, memory_scope_device);
}
