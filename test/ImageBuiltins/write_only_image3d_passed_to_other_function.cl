// RUN: clspv %s -o %t.spv -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

#pragma OPENCL EXTENSION cl_khr_3d_image_writes : enable

void bar(write_only image3d_t i, int4 c, float4 a)
{
  write_imagef(i, c, a);
}

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(write_only image3d_t i, int4 c, global float4* a)
{
  bar(i, c, *a);
}
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_2:%[0-9a-zA-Z_]+]] = OpTypeImage [[_float]] 3D 0 0 0 2 Unknown
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK-DAG:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpFunction
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_v4uint]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_v4float]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpLoad [[_2]]
// CHECK:  OpImageWrite [[_26]] [[_23]] [[_24]]
// CHECK:  = OpFunction
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpLoad [[_2]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpLoad [[_v4uint]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpFunctionCall {{.*}} [[_21]] [[_29]] [[_31]] [[_33]]
