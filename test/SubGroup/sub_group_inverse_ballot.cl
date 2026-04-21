// RUN: clspv %target %s -cl-std=CL3.0 -inline-entry-points -o %t.spv -spv-version=1.3
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env spv1.3 %t.spv

// CHECK: %[[BOOL_TY:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK: %[[BALLOT_ID:[a-zA-Z0-9_]*]] = OpGroupNonUniformInverseBallot %[[BOOL_TY]] %uint_3 %[[MASK_ID:[0-9]*]]

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

void kernel test(global uint4 *a, global int *b)
{
  uint index = get_global_id(0);
  uint4 mask = a[index];
  b[index] = sub_group_inverse_ballot(mask);
}
