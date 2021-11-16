// RUN: clspv %s -cl-std=CL3.0 -spv-version=1.3 -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

void kernel test(global uint *c)
{
  *c = get_max_sub_group_size();
}

// CHECK: [[extinst:%[a-zA-Z0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.2"
// CHECK: OpDecorate [[max_subgroup_size_constant:%[a-zA-Z0-9_]+]] SpecId 3
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[uint_3:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 3
// CHECK-DAG: [[max_subgroup_size_constant]] = OpSpecConstant [[uint]] 1
// CHECK-DAG: [[ptr_private_uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[uint]]
// CHECK-DAG: [[max_subgroup_size_var:%[a-zA-Z0-9_]+]] = OpVariable [[ptr_private_uint]] Private [[max_subgroup_size_constant]]
// CHECK: [[max_subgroup_size_loaded_value:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] [[max_subgroup_size_var]]
// CHECK: OpStore {{.*}} [[max_subgroup_size_loaded_value]]
// CHECK: OpExtInst [[void]] [[extinst]] SpecConstantSubgroupMaxSize [[uint_3]]
