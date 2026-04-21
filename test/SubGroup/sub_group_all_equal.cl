// RUN: clspv %target %s -cl-std=CL3.0 -inline-entry-points -o %t.spv -spv-version=1.3
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env spv1.3 %t.spv

// CHECK: %[[BOOL_TY:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK: %[[EQUALS_ID:[a-zA-Z0-9_]*]] = OpGroupNonUniformAllEqual %[[BOOL_TY]] %uint_3 %[[VALUE_ID:[0-9]*]]

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

void kernel test(global int *a, global int *b)
{
  uint gid = get_global_id(0);
  int value = a[gid];
  b[gid] = sub_group_non_uniform_all_equal(value);
}
