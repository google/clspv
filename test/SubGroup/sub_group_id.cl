// RUN: clspv %s -cl-std=CL2.0 -spv-version=1.3 -inline-entry-points -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv



#pragma OPENCL EXTENSION cl_khr_subgroups : enable

// CHECK: OpDecorate %[[SUBGROUP_ID:[a-zA-Z0-9_]*]] BuiltIn SubgroupId
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
void kernel test(global uint *c)
{
  uint i = get_global_id(0);
  // CHECK: %[[SUBGROUP_ID]] = OpVariable %[[_ptr_Input_uint:[a-zA-Z0-9_]*]] Input
  // CHECK: %[[LOAD_31:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[SUBGROUP_ID]]

  c[i] = get_sub_group_id();
}
