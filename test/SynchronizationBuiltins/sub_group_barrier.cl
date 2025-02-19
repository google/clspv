// RUN: clspv %target %s -o %t.spv --cl-std=CL2.0 -inline-entry-points --spv-version=1.3
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

// CHECK: [[uint:%[a-zA-Z0-9_.]+]] = OpTypeInt 32 0

// Subgroup
// CHECK-DAG: [[uint_3:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 3

// Relaxed
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// AcquireRelease | StorageBufferMemory
// CHECK-DAG: [[uint_72:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 72
// AcquireRelease | WorkgroupMemory
// CHECK-DAG: [[uint_264:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 264
// AcquireRelease | StorageBufferMemory | WorkgroupMemory
// CHECK-DAG: [[uint_328:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 328

// CHECK: OpControlBarrier [[uint_3]] [[uint_3]] [[uint_0]]
// CHECK: OpControlBarrier [[uint_3]] [[uint_3]] [[uint_72]]
// CHECK: OpControlBarrier [[uint_3]] [[uint_3]] [[uint_264]]
// CHECK: OpControlBarrier [[uint_3]] [[uint_3]] [[uint_328]]

kernel void foo() {
  sub_group_barrier(0);
  sub_group_barrier(CLK_GLOBAL_MEM_FENCE);
  sub_group_barrier(CLK_LOCAL_MEM_FENCE);
  sub_group_barrier(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE);
}
