// RUN: clspv %target %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__attribute__((noinline))
float4 bar(sampler_t s, read_only image2d_t i, float2 c)
{
  return read_imagef(i, s, c);
}

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(sampler_t s, read_only image2d_t i, float2 c, global float4* a)
{
  *a = bar(s, i, c);
}
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_2:%[0-9a-zA-Z_]+]] = OpTypeSampler
// CHECK-DAG:  [[_4:%[0-9a-zA-Z_]+]] = OpTypeImage [[_float]] 2D 0 0 0 1 Unknown
// CHECK-DAG:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG:  [[_19:%[0-9a-zA-Z_]+]] = OpTypeSampledImage [[_4]]
// CHECK-DAG:  [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK:  = OpFunction
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_v4float]] [[_26:%[0-9a-zA-Z_]+]]
// CHECK:  OpStore {{.*}} [[_42]]
// CHECK:  [[_26]] = OpFunction [[_v4float]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_v2float]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpLoad [[_4]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpLoad [[_2]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpSampledImage [[_19]] [[_31]] [[_32]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpImageSampleExplicitLod [[_v4float]] [[_33]] [[_29]] Lod [[_float_0]]
// CHECK:  OpReturnValue [[_34]]
