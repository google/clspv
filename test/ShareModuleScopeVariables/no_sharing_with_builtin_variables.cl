// RUN: clspv %target %s -cl-std=CL3.0 -spv-version=1.3 -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

kernel void foo(global uint *in, global uint *out, uint n) {
  local uint foo_local;
  foo_local = in[n];
  barrier(CLK_LOCAL_MEM_FENCE);
  out[n] = foo_local + get_max_sub_group_size();
}

kernel void bar(global uint *in, global uint *out, uint n) {
  local uint bar_local;
  bar_local = in[n];
  barrier(CLK_LOCAL_MEM_FENCE);
  out[n] = bar_local + get_work_dim();
}

// foo_local and bar_local should be shared, but not with the private
// variables of the same type that clspv creates for get_max_sub_group_size()
// and get_work_dim().

// CHECK-DAG: OpDecorate [[spec_id_3:%[a-zA-Z0-9_]+]] SpecId 3
// CHECK-DAG: OpDecorate [[spec_id_4:%[a-zA-Z0-9_]+]] SpecId 4
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[workgroup_uint:%[a-zA-Z0-9_]+]] = OpTypePointer Workgroup [[uint]]
// CHECK-DAG: [[private_uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[uint]]
// CHECK-NOT: OpVariable {{.*}} Workgroup
// CHECK: OpVariable [[workgroup_uint]] Workgroup
// CHECK-NOT: OpVariable {{.*}} Workgroup
// CHECK-DAG: OpVariable [[private_uint]] Private [[spec_id_3]]
// CHECK-DAG: OpVariable [[private_uint]] Private [[spec_id_4]]
// CHECK-NOT: OpVariable {{.*}} Workgroup
