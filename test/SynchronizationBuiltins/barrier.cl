// RUN: clspv %target %s -o %t.spv --cl-std=CL2.0 --inline-entry-points
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[uint:%[a-zA-Z0-9_.]+]] = OpTypeInt 32 0

// CHECK-DAG: [[wg:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 2

// CHECK-DAG: [[Rx:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[AcqRel_Uniform:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 72
// CHECK-DAG: [[AcqRel_Workgroup:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 264
// CHECK-DAG: [[AcqRel_Image:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 2056
// CHECK-DAG: [[AcqRel_Uniform_Workgroup_Image:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 2376

// CHECK: OpControlBarrier [[wg]] [[wg]] [[Rx]]
// CHECK: OpControlBarrier [[wg]] [[wg]] [[AcqRel_Uniform]]
// CHECK: OpControlBarrier [[wg]] [[wg]] [[AcqRel_Workgroup]]
// CHECK: OpControlBarrier [[wg]] [[wg]] [[AcqRel_Image]]
// CHECK: OpControlBarrier [[wg]] [[wg]] [[AcqRel_Uniform_Workgroup_Image]]

kernel void foo() {
  barrier(0);
  barrier(CLK_GLOBAL_MEM_FENCE);
  barrier(CLK_LOCAL_MEM_FENCE);
  barrier(CLK_IMAGE_MEM_FENCE);
  barrier(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE | CLK_IMAGE_MEM_FENCE);
}
