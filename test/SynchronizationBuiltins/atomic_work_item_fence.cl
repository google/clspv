// RUN: clspv %target %s -o %t.spv --cl-std=CL3.0
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo() {
  atomic_work_item_fence(CLK_LOCAL_MEM_FENCE, memory_order_acq_rel, memory_scope_work_group);
  atomic_work_item_fence(CLK_GLOBAL_MEM_FENCE, memory_order_acquire, memory_scope_device);
  atomic_work_item_fence(CLK_IMAGE_MEM_FENCE, memory_order_release, memory_scope_work_item);
  atomic_work_item_fence(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE | CLK_IMAGE_MEM_FENCE, memory_order_acq_rel, memory_scope_device);
}

// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[int_1:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 1
// CHECK-DAG: [[int_2:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2
// acq/rel workgroup
// CHECK-DAG: [[int_264:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 264
// acq uniform
// CHECK-DAG: [[int_66:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 66
// acq/rel uniform|workgroup|image
// CHECK-DAG: [[int_2376:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2376
// CHECK: OpMemoryBarrier [[int_2]] [[int_264]]
// CHECK: OpMemoryBarrier [[int_1]] [[int_66]]
// CHECK: OpMemoryBarrier [[int_1]] [[int_2376]]
