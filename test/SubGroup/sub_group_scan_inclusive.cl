// RUN: clspv %target %s -cl-std=CL2.0 -spv-version=1.3 -inline-entry-points -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv



#pragma OPENCL EXTENSION cl_khr_subgroups : enable

void kernel test(global uint *c)
{
  uint i = get_global_id(0);
  int j = 256 - i;
  c += i * 5;
  // CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
  // CHECK-DAG: %[[UINT_3:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 3

  // CHECK: %[[_35:[a-zA-Z0-9_]*]] = OpGroupNonUniformIAdd %[[UINT_TYPE_ID]] %[[UINT_3]] InclusiveScan %[[_29:[a-zA-Z0-9_]*]]
  c[0] = sub_group_scan_inclusive_add(i);
  // CHECK: %[[_38:[a-zA-Z0-9_]*]] = OpGroupNonUniformUMin %[[UINT_TYPE_ID]] %[[UINT_3]] InclusiveScan %[[_29]]
  c[1] = sub_group_scan_inclusive_min(i);
  // CHECK: %[[_41:[a-zA-Z0-9_]*]] = OpGroupNonUniformUMax %[[UINT_TYPE_ID]] %[[UINT_3]] InclusiveScan %[[_29]]
  c[2] = sub_group_scan_inclusive_max(i);
  // CHECK: %[[_44:[a-zA-Z0-9_]*]] = OpGroupNonUniformSMin %[[UINT_TYPE_ID]] %[[UINT_3]] InclusiveScan %[[_31:[a-zA-Z0-9_]*]]
  c[3] = sub_group_scan_inclusive_min(j);
  // CHECK: %[[_48:[a-zA-Z0-9_]*]] = OpGroupNonUniformSMax %[[UINT_TYPE_ID]] %[[UINT_3]] InclusiveScan %[[_31]]
  c[4] = sub_group_scan_inclusive_max(j);
}
