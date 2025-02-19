// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[uint:%[a-zA-Z0-9_.]+]] = OpTypeInt 32 0

// Workgroup
// CHECK-DAG: [[uint_2:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 2

// Relaxed
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// AcquireRelease | StorageBufferMemory
// CHECK-DAG: [[uint_72:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 72
// AcquireRelease | WorkgroupMemory
// CHECK-DAG: [[uint_264:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 264
// AcquireRelease | StorageBufferMemory | WorkgroupMemory
// CHECK-DAG: [[uint_328:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 328

// CHECK: OpControlBarrier [[uint_2]] [[uint_2]] [[uint_0]]
// CHECK: OpControlBarrier [[uint_2]] [[uint_2]] [[uint_72]]
// CHECK: OpControlBarrier [[uint_2]] [[uint_2]] [[uint_264]]
// CHECK: OpControlBarrier [[uint_2]] [[uint_2]] [[uint_328]]

kernel void foo() {
  barrier(0);
  barrier(CLK_GLOBAL_MEM_FENCE);
  barrier(CLK_LOCAL_MEM_FENCE);
  barrier(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE);
}
