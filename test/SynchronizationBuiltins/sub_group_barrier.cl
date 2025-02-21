// RUN: clspv %target %s -o %t.spv --cl-std=CL2.0 --inline-entry-points --spv-version=1.3
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

// CHECK: [[uint:%[a-zA-Z0-9_.]+]] = OpTypeInt 32 0

// CHECK-DAG: [[sb:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 3

// CHECK-DAG: [[Rx:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[AcqRel_Uniform:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 72
// CHECK-DAG: [[AcqRel_Workgroup:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 264
// CHECK-DAG: [[AcqRel_Image:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 2056
// CHECK-DAG: [[AcqRel_Uniform_Workgroup_Image:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 2376

// CHECK: OpControlBarrier [[sb]] [[sb]] [[Rx]]
// CHECK: OpControlBarrier [[sb]] [[sb]] [[AcqRel_Uniform]]
// CHECK: OpControlBarrier [[sb]] [[sb]] [[AcqRel_Workgroup]]
// CHECK: OpControlBarrier [[sb]] [[sb]] [[AcqRel_Image]]
// CHECK: OpControlBarrier [[sb]] [[sb]] [[AcqRel_Uniform_Workgroup_Image]]

kernel void foo() {
  sub_group_barrier(0);
  sub_group_barrier(CLK_GLOBAL_MEM_FENCE);
  sub_group_barrier(CLK_LOCAL_MEM_FENCE);
  sub_group_barrier(CLK_IMAGE_MEM_FENCE);
  sub_group_barrier(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE | CLK_IMAGE_MEM_FENCE);
}
