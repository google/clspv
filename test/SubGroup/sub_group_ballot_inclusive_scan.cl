// RUN: clspv %target %s -cl-std=CL3.0 -inline-entry-points -o %t.spv -spv-version=1.3
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env spv1.3 %t.spv

// CHECK: %[[UINT_TY:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK: %[[COUNT_ID:[a-zA-Z0-9_]*]] = OpGroupNonUniformBallotBitCount %[[UINT_TY]] %uint_3 InclusiveScan %[[VALUE_ID:[0-9]*]]

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

void kernel test(global uint4 *a, global uint *b)
{
  uint gid = get_global_id(0);
  uint4 value = a[gid];
  b[gid] = sub_group_ballot_inclusive_scan(value);
}
