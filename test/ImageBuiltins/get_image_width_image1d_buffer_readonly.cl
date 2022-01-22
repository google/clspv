// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1)))
foo(global int* out, read_only image1d_buffer_t im)
{
  *out = get_image_width(im);
}

// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_8:%[0-9a-zA-Z_]+]] = OpTypeImage [[_float]] Buffer 0 0 0 2 Unknown
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_18:%[0-9a-zA-Z_]+]] = OpLoad [[_8]]
// CHECK: [[_19:%[0-9a-zA-Z_]+]] = OpImageQuerySize [[_uint]] [[_18]]
// CHECK: OpStore {{.*}} [[_19]]

