// RUN: clspv %target %s -o %t.spv -cluster-pod-kernel-args=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t4.spv
// RUN: spirv-dis -o %t4.spvasm %t4.spv
// RUN: FileCheck %s < %t4.spvasm -check-prefix=CLUSTER
// RUN: spirv-val --target-env vulkan1.0 %t4.spv


void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(sampler_t s, read_only image3d_t i, float4 c, global uint4* a)
{
  *a = read_imageui(i, s, c);
}

// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_2:%[0-9a-zA-Z_]+]] = OpTypeSampler
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK-DAG:  [[_4:%[0-9a-zA-Z_]+]] = OpTypeImage [[_uint]] 3D 0 0 0 1 Unknown
// CHECK-DAG:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG:  [[ptr_uniform_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[_v4float]]
// CHECK-DAG: [[_18:%[a-zA-Z0-9_]+]] = OpTypeSampledImage [[_4]]
// CHECK-DAG: [[_float_0_0625:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0.0625
// CHECK-DAG: [[_float_0_5:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0.5
// CHECK-DAG: [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpLoad [[_2]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_4]]
// CHECK:  [[gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[ptr_uniform_v4float]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[gep]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpSampledImage [[_18]] [[_28]] [[_27]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpImageSampleExplicitLod [[_v4uint]] [[_32]] {{.*}} Lod [[_float_0]]
// CHECK:  OpStore {{.*}} [[_33]]

// In a second round, check -cluster-pod-kernel-args

// CLUSTER-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CLUSTER-DAG: [[_2:%[a-zA-Z0-9_]+]] = OpTypeSampler
// CLUSTER-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CLUSTER-DAG: [[ptr_pushconstant_uint:%[0-9a-zA-Z_]+]] = OpTypePointer PushConstant [[_uint]]
// CLUSTER-DAG: [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CLUSTER-DAG: [[_4:%[0-9a-zA-Z_]+]] = OpTypeImage [[_uint]] 3D 0 0 0 1 Unknown
// CLUSTER-DAG: [[_v4float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 4
// CLUSTER-DAG: [[_19:%[a-zA-Z0-9_]+]] = OpTypeSampledImage [[_4]]
// CLUSTER-DAG: [[_float_0_0625:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0.0625
// CLUSTER-DAG: [[_float_0_5:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0.5
// CLUSTER-DAG: [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CLUSTER: [[_28:%[a-zA-Z0-9_]+]] = OpLoad [[_2]]
// CLUSTER: [[_29:%[a-zA-Z0-9_]+]] = OpLoad [[_4]]
// CLUSTER-COUNT-4: [[_32:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_pushconstant_uint]]
// CLUSTER: [[_34:%[a-zA-Z0-9_]+]] = OpSampledImage [[_19]] [[_29]] [[_28]]
// CLUSTER: [[_35:%[a-zA-Z0-9_]+]] = OpImageSampleExplicitLod [[_v4uint]] [[_34]] {{.*}} Lod [[_float_0]]
// CLUSTER: OpStore {{.*}} [[_35]]


