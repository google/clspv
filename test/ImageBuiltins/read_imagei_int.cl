// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(read_only image1d_t i, int c, global int4* a)
{
  *a = read_imagei(i, c);
}

// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK-DAG:  [[_int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 1
// CHECK-DAG:  [[_v4int:%[0-9a-zA-Z_]+]] = OpTypeVector [[_int]] 4
// CHECK-DAG:  [[_4:%[0-9a-zA-Z_]+]] = OpTypeImage [[_int]] 1D 0 0 0 1 Unknown
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_4]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpImageFetch [[_v4int]] [[_28]] [[_30]]
// CHECK:  [[cast:%[0-9a-zA-Z_]+]] = OpBitcast [[_v4uint]] [[_33]]
// CHECK:  OpStore {{.*}} [[cast]]

