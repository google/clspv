// RUN: clspv %target %s -cl-std=CL3.0 -inline-entry-points -long-vector -o %t.spv -spv-version=1.5
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env spv1.5 %t.spv

// CHECK: %[[BROADCAST_ID:[a-zA-Z0-9_]*]] = OpGroupNonUniformBroadcast %uint %uint_3 %[[REG_ID:[0-9]*]] %[[LANE_ID:[0-9]*]]
// CHECK-COUNT-4: OpGroupNonUniformBroadcast %v4uchar %uint_3

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

void kernel test(global uint *a, global uint *b, uint lane)
{
  uint index = get_global_id(0);
  uint value = a[index];
  b[index] = sub_group_non_uniform_broadcast(value, lane);
}

void kernel test_char16(global char16 *a, global char16 *b, uint lane)
{
  uint index = get_global_id(0);
  char16 value = a[index];
  b[index] = sub_group_non_uniform_broadcast(value, lane);
}
