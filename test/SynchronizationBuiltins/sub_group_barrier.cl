// RUN: clspv %s -o %t.spv --cl-std=CL2.0 -inline-entry-points --spv-version=1.3
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

// CHECK: [[uint:%[a-zA-Z0-9_.]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_3:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 3
// CHECK-DAG: [[uint_264:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 264
// CHECK: OpControlBarrier [[uint_3]] [[uint_3]] [[uint_264]]
kernel void foo() {
  sub_group_barrier(CLK_LOCAL_MEM_FENCE);
}

