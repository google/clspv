// RUN: clspv %target %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__attribute__((noinline))
void bar(write_only image2d_t i, int2 c, float4 a)
{
  write_imagef(i, c, a);
}

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(write_only image2d_t i, int2 c, global float4* a)
{
  bar(i, c, *a);
}
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_2:%[0-9a-zA-Z_]+]] = OpTypeImage [[_float]] 2D 0 0 0 2 Unknown
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  = OpFunction
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_v2uint]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpFunctionCall {{.*}} [[_21:%[0-9a-zA-Z_]+]] [[_31]] [[_33]]
// CHECK:  [[_21]] = OpFunction
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_v2uint]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_v4float]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpLoad [[_2]]
// CHECK:  OpImageWrite [[_26]] [[_23]] [[_24]]
