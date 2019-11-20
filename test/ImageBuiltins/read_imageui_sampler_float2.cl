// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t4.spv -cluster-pod-kernel-args
// RUN: spirv-dis -o %t4.spvasm %t4.spv
// RUN: FileCheck %s < %t4.spvasm -check-prefix=CLUSTER
// RUN: spirv-val --target-env vulkan1.0 %t4.spv


void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(sampler_t s, read_only image2d_t i, float2 c, global uint4* a)
{
  *a = read_imageui(i, s, c);
}

// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_2:%[0-9a-zA-Z_]+]] = OpTypeSampler
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK-DAG:  [[_4:%[0-9a-zA-Z_]+]] = OpTypeImage [[_uint]] 2D 0 0 0 1 Unknown
// CHECK-DAG:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_18:%[a-zA-Z0-9_]+]] = OpTypeSampledImage [[_4]]
// CHECK-DAG: [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpLoad [[_2]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_4]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpLoad [[_v2float]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpSampledImage [[_18]] [[_28]] [[_27]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpImageSampleExplicitLod [[_v4uint]] [[_32]] [[_30]] Lod [[_float_0]]
// CHECK:  OpStore {{.*}} [[_33]]

// In a second round, check -cluster-pod-kernel-args

// CLUSTER-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CLUSTER-DAG: [[_2:%[a-zA-Z0-9_]+]] = OpTypeSampler
// CLUSTER-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CLUSTER-DAG: [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CLUSTER-DAG: [[_4:%[0-9a-zA-Z_]+]] = OpTypeImage [[_uint]] 2D 0 0 0 1 Unknown
// CLUSTER-DAG: [[_v2float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 2
// CLUSTER-DAG: [[__struct_12:%[a-zA-Z0-9_]+]] = OpTypeStruct [[_v2float]]
// CLUSTER-DAG: [[_19:%[a-zA-Z0-9_]+]] = OpTypeSampledImage [[_4]]
// CLUSTER-DAG: [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CLUSTER: [[_28:%[a-zA-Z0-9_]+]] = OpLoad [[_2]]
// CLUSTER: [[_29:%[a-zA-Z0-9_]+]] = OpLoad [[_4]]
// CLUSTER: [[_32:%[a-zA-Z0-9_]+]] = OpLoad [[__struct_12]]
// CLUSTER: [[_33:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_v2float]] [[_32]] 0
// CLUSTER: [[_34:%[a-zA-Z0-9_]+]] = OpSampledImage [[_19]] [[_29]] [[_28]]
// CLUSTER: [[_35:%[a-zA-Z0-9_]+]] = OpImageSampleExplicitLod [[_v4uint]] [[_34]] [[_33]] Lod [[_float_0]]
// CLUSTER: OpStore {{.*}} [[_35]]

