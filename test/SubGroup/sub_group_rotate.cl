// RUN: clspv %target %s -cl-std=CL2.0 -spv-version=1.3 -inline-entry-points -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

// CHECK: OpExtension "SPV_KHR_subgroup_rotate"
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[subgroup:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 3
// CHECK: OpGroupNonUniformRotateKHR {{%[a-zA-Z0-9_]+}} [[subgroup]] {{%[a-zA-Z0-9_]+}} {{%[a-zA-Z0-9_]+}}

kernel void test(global int* out, global int* in) {
  out[0] = sub_group_rotate(in[0], 1);
}
