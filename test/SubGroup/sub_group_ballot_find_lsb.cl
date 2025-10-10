// RUN: clspv -spv-version=1.3 %target -cl-std=CL2.0 -inline-entry-points %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// CHECK: OpCapability GroupNonUniformBallot

// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[vec4:%[a-zA-Z0-9_]+]] = OpTypeVector [[uint]] 4
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[subgroup_scope:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 3

// CHECK-DAG: [[gid_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain %_ptr_Input_uint %gl_GlobalInvocationID [[uint_0]]
// CHECK-DAG: [[gid:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] [[gid_ptr]]
// CHECK-DAG: [[in_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain %_ptr_StorageBuffer_v4uint {{%[a-zA-Z0-9_]+}} %uint_0 {{%[a-zA-Z0-9_]+}}
// CHECK-DAG: [[mask:%[a-zA-Z0-9_]+]] = OpLoad [[vec4]] [[in_ptr]] Aligned 16
// CHECK-DAG: [[lsb:%[a-zA-Z1-9_]+]] = OpGroupNonUniformBallotFindLSB [[uint]] [[subgroup_scope]] [[mask]]
// CHECK-DAG: [[ins:%[a-zA-Z0-9_]+]] = OpCompositeInsert [[vec4]] [[lsb]] {{%[a-zA-Z0-9_]+}} 0
// CHECK-DAG: [[rep:%[a-zA-Z0-9_]+]] = OpVectorShuffle [[vec4]] [[ins]] {{%[a-zA-Z0-9_]+}} 0 0 0 0
// CHECK-DAG: [[out_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain %_ptr_StorageBuffer_v4uint {{%[a-zA-Z0-9_]+}} %uint_0 {{%[a-zA-Z0-9_]+}}
// CHECK-DAG: OpStore [[out_ptr]] [[rep]] Aligned 16

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

kernel void test(global uint4* out, global uint4* in) {
  uint gid = get_global_id(0);
  uint4 mask = in[gid];
  out[gid] = sub_group_ballot_find_lsb(mask);
}
