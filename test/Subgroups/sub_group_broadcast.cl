// RUN: clspv %s -cl-std=CL2.0 --spirv-version=1.5 -inline-entry-points -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// CHECK: %[[BROADCAST_ID:[a-zA-Z0-9_]*]] = OpGroupNonUniformBroadcast %float %uint_3 %[[REG_ID:[0-9]*]] %[[LANE_ID:[0-9]*]]


#pragma OPENCL EXTENSION cl_khr_subgroups : enable

void kernel test(global float *a, global float *b, global float *c)
{
  size_t x = get_global_id(0);
  a += x;
  b += x;
  c += x;
  float v = 0;
  float lb = *b;
  for (uint i=0; i<32; ++i) {
    float t = sub_group_broadcast(lb, i);
    v += *a * t;
  }
  *c = v;
}
