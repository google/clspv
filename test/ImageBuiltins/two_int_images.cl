// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(sampler_t s, read_only image2d_t i, float2 c, global int4* a)
{
  *a = read_imagei(i, s, c);
}

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) bar(sampler_t s, read_only image3d_t i, float4 c, global int4* a)
{
  *a = read_imagei(i, s, c);
}

// CHECK-DAG: OpEntryPoint GLCompute [[foo:%[a-zA-Z0-9_]+]] "foo"
// CHECK-DAG: OpEntryPoint GLCompute [[bar:%[a-zA-Z0-9_]+]] "bar"
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_2:%[0-9a-zA-Z_]+]] = OpTypeSampler
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK-DAG:  [[_int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 1
// CHECK-DAG:  [[_v4int:%[0-9a-zA-Z_]+]] = OpTypeVector [[_int]] 4
// CHECK-DAG:  [[_2D:%[0-9a-zA-Z_]+]] = OpTypeImage [[_int]] 2D 0 0 0 1 Unknown
// CHECK-DAG:  [[_3D:%[0-9a-zA-Z_]+]] = OpTypeImage [[_int]] 3D 0 0 0 1 Unknown
// CHECK-DAG:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[sampled2D:%[a-zA-Z0-9_]+]] = OpTypeSampledImage [[_2D]]
// CHECK-DAG: [[sampled3D:%[a-zA-Z0-9_]+]] = OpTypeSampledImage [[_3D]]
// CHECK-DAG: [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK:  [[foo]] = OpFunction
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpLoad [[_2]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_2D]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_v2float]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpSampledImage [[sampled2D]] [[_28]] [[_27]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpImageSampleExplicitLod [[_v4int]] [[_32]] [[_30]] Lod [[_float_0]]
// CHECK:  [[cast:%[0-9a-zA-Z_]+]] = OpBitcast [[_v4uint]] [[_33]]
// CHECK:  OpStore {{.*}} [[cast]]
// CHECK:  [[bar]] = OpFunction
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpLoad [[_2]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_3D]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_v4float]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpSampledImage [[sampled3D]] [[_28]] [[_27]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpImageSampleExplicitLod [[_v4int]] [[_32]] [[_30]] Lod [[_float_0]]
// CHECK:  [[cast:%[0-9a-zA-Z_]+]] = OpBitcast [[_v4uint]] [[_33]]
// CHECK:  OpStore {{.*}} [[cast]]
