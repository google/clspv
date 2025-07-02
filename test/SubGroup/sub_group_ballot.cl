// RUN: clspv -spv-version=1.3 %target -cl-std=CL2.0 -inline-entry-points %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// CHECK: OpCapability GroupNonUniformBallot

// CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[vec4:%[a-zA-Z0-9_]+]] = OpTypeVector [[uint]] 4
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[subgroup_scope:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 3

// CHECK-DAG: [[gid_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain %_ptr_Input_uint %gl_GlobalInvocationID [[uint_0]]
// CHECK-DAG: [[gid:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] [[gid_ptr]]
// CHECK-DAG: [[in_base:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] {{%[a-zA-Z0-9_]+}} Aligned 4
// CHECK-DAG: [[pred:%[a-zA-Z0-9_]+]] = OpINotEqual [[bool]] [[in_base]] [[uint_0]]
// CHECK-DAG: [[cond:%[a-zA-Z0-9_]+]] = OpSelect [[uint]] [[pred]] [[uint_1]] [[uint_0]]
// CHECK-DAG: [[cmp:%[a-zA-Z0-9_]+]] = OpINotEqual [[bool]] [[cond]] [[uint_0]]
// CHECK-DAG: [[ballot:%[a-zA-Z0-9_]+]] = OpGroupNonUniformBallot [[vec4]] [[subgroup_scope]] [[cmp]]
// CHECK-DAG: OpStore {{%[a-zA-Z0-9_]+}} [[ballot]] Aligned 16

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

kernel void test(global uint4* out, global int* in) {
  uint gid = get_global_id(0);
  bool pred = in[gid] != 0;
  out[gid] = sub_group_ballot(pred);
}
