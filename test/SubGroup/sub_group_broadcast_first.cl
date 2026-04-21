// RUN: clspv %target %s -cl-std=CL3.0 -inline-entry-points -o %t.spv -spv-version=1.3
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env spv1.3 %t.spv

// CHECK: %[[BROADCAST_ID:[a-zA-Z0-9_]*]] = OpGroupNonUniformBroadcastFirst %uint %uint_3 %[[REG_ID:[0-9]*]]

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

void kernel test(global uint *a, global uint *b)
{
  uint index = get_global_id(0);
  uint value = a[index];
  b[index] = sub_group_broadcast_first(value);
}
