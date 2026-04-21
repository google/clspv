// RUN: clspv -spv-version=1.3 %target -cl-std=CL3.0 -inline-entry-points %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

// CHECK-DAG: %[[UINT_TY:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[VEC3_TY:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TY]] 3
// CHECK: %[[WGSIZE_ID:[a-zA-Z0-9_]*]] = OpSpecConstantComposite %[[VEC3_TY]]
// CHECK: %[[WG_X:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[UINT_TY]] %[[WGSIZE_ID]] 0
// CHECK: %[[WG_Y:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[UINT_TY]] %[[WGSIZE_ID]] 1
// CHECK: %[[WG_Z:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[UINT_TY]] %[[WGSIZE_ID]] 2
// CHECK: %[[FLAT_WG_XY:[a-zA-Z0-9_]*]] = OpIMul %[[UINT_TY]] %[[WG_X]] %[[WG_Y]]
// CHECK: %[[FLAT_WG:[a-zA-Z0-9_]*]] = OpIMul %[[UINT_TY]] %[[FLAT_WG_XY]] %[[WG_Z]]
// CHECK: %[[SUBSTART:[a-zA-Z0-9_]*]] = OpIMul %[[UINT_TY]] %{{.*}} %{{.*}}
// CHECK: %[[REMAINING:[a-zA-Z0-9_]*]] = OpISub %[[UINT_TY]] %[[FLAT_WG]] %[[SUBSTART]]
// CHECK: %[[UMIN:[a-zA-Z0-9_]*]] = OpExtInst %[[UINT_TY]] %{{.*}} UMin %[[REMAINING]]

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

kernel void test(global uint* out) {
  *out = get_sub_group_size();
}
