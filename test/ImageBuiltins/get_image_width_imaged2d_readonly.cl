// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// #219: Sampled images cannot be queried in Vulkan.
// RUN: not spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1)))
foo(global int* out, read_only image2d_t im)
{
  *out = get_image_width(im);
}

// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_8:%[0-9a-zA-Z_]+]] = OpTypeImage [[_float]] 2D 0 0 0 1 Unknown
// CHECK: [[_18:%[0-9a-zA-Z_]+]] = OpLoad [[_8]]
// CHECK: [[_19:%[0-9a-zA-Z_]+]] = OpImageQuerySize [[_v2uint]] [[_18]]
// CHECK: [[_20:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_19]] 0
// CHECK: OpStore {{.*}} [[_20]]
