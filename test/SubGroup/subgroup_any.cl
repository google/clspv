// RUN: clspv -spv-version=1.3 %target -cl-std=CL2.0 -inline-entry-points %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

// CHECK: OpCapability GroupNonUniformVote
// CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[int_0:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK-DAG: [[int_1:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 1
// CHECK-DAG: [[subgroup:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 3
// CHECK: [[cmp:%[a-zA-Z0-9_]+]] = OpINotEqual [[bool]] {{.*}} [[int_0]]
// CHECK: [[any:%[a-zA-Z0-9_]+]] = OpGroupNonUniformAny [[bool]] [[subgroup]] [[cmp]]
// CHECK: OpSelect [[int]] [[any]] [[int_1]] [[int_0]]

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

kernel void test(global int* out, global int *in) {
  *out = sub_group_any(*in);
}
