// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

#pragma OPENCL EXTENSION cl_khr_3d_image_writes : enable

void kernel __attribute__((reqd_work_group_size(1, 1, 1)))
foo(global int* out, write_only image3d_t im)
{
  *out = get_image_width(im);
}
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_8:%[0-9a-zA-Z_]+]] = OpTypeImage [[_float]] 3D 0 0 0 2 Unknown
// CHECK: [[_18:%[0-9a-zA-Z_]+]] = OpLoad [[_8]]
// CHECK: [[_19:%[0-9a-zA-Z_]+]] = OpImageQuerySize [[_v3uint]] [[_18]]
// CHECK: [[_20:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_19]] 0
// CHECK: OpStore {{.*}} [[_20]]

