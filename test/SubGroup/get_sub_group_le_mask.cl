// RUN: clspv %target %s -cl-std=CL2.0 -spv-version=1.3 -inline-entry-points -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

// CHECK: OpCapability GroupNonUniformBallot
// CHECK: OpDecorate %[[VAR:[a-zA-Z0-9_]+]] BuiltIn SubgroupLeMask
// CHECK-DAG: %[[UINT:[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[VEC4:[a-zA-Z0-9_]+]] = OpTypeVector %[[UINT]] 4
// CHECK-DAG: %[[PTR:[a-zA-Z0-9_]+]] = OpTypePointer Input %[[VEC4]]
// CHECK: %[[VAR]] = OpVariable %[[PTR]] Input
// CHECK: OpLoad %[[VEC4]] %[[VAR]]

kernel void test(global uint4 *out) {
  out[0] = get_sub_group_le_mask();
}
