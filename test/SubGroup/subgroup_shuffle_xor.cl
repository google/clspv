// RUN: clspv -spv-version=1.3 %target -cl-std=CL2.0 -inline-entry-points %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

// CHECK: OpCapability GroupNonUniformShuffle
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_3:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 3
// CHECK-DAG: [[xor_index:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] {{.*}}Aligned 16
// CHECK-DAG: [[load_in:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] {{.*}}Aligned 4
// CHECK-DAG: [[shuffled:%[a-zA-Z0-9_]+]] = OpGroupNonUniformShuffleXor [[uint]] [[uint_3]] [[load_in]] [[xor_index]]
// CHECK-DAG: OpStore {{.*}} [[shuffled]]

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

kernel void test(global int* out, global int* in, int xor_index) {
  int gid = get_global_id(0);
  int value = in[gid];
  int shuffled_value = sub_group_shuffle_xor(value, xor_index);
  out[gid] = shuffled_value;
}
