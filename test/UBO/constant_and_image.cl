// RUN: clspv -constant-args-ubo -inline-entry-points %s -o %t.spv -descriptormap=%t2.map -cluster-pod-kernel-args=0 -pod-ubo
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t2.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(read_only image2d_t i, sampler_t s, constant float4* offset, float2 c, global float4* data) {
  *data = read_imagef(i, s, c) + *offset;
}

//      MAP: kernel,foo,arg,i,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,ro_image
// MAP-NEXT: kernel,foo,arg,s,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,sampler
// MAP-NEXT: kernel,foo,arg,offset,argOrdinal,2,descriptorSet,0,binding,2,offset,0,argKind,buffer_ubo
// MAP-NEXT: kernel,foo,arg,c,argOrdinal,3,descriptorSet,0,binding,3,offset,0,argKind,pod_ubo,argSize,8
// MAP-NEXT: kernel,foo,arg,data,argOrdinal,4,descriptorSet,0,binding,4,offset,0,argKind,buffer

// CHECK-DAG: OpDecorate [[runtime:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK-DAG: OpDecorate [[image_var:%[0-9a-zA-Z_]+]] Binding 0
// CHECK-DAG: OpDecorate [[image_var]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[sampler_var:%[0-9a-zA-Z_]+]] Binding 1
// CHECK-DAG: OpDecorate [[sampler_var]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[offset_var:%[0-9a-zA-Z_]+]] Binding 2
// CHECK-DAG: OpDecorate [[offset_var]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[offset_var]] NonWritable
// CHECK-DAG: OpDecorate [[c_var:%[0-9a-zA-Z_]+]] Binding 3
// CHECK-DAG: OpDecorate [[c_var]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[data_var:%[0-9a-zA-Z_]+]] Binding 4
// CHECK-DAG: OpDecorate [[data_var]] DescriptorSet 0
// CHECK: [[float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK: [[image:%[0-9a-zA-Z_]+]] = OpTypeImage [[float]] 2D 0 0 0 1 Unknown
// CHECK: [[sampled_image:%[0-9a-zA-Z_]+]] = OpTypeSampledImage [[image]]
// CHECK: [[image_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer UniformConstant [[image]]
// CHECK: [[sampler:%[0-9a-zA-Z_]+]] = OpTypeSampler
// CHECK: [[sampler_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer UniformConstant [[sampler]]
// CHECK: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[float]] 4
// CHECK: [[int_4096:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 4096
// CHECK: [[array:%[0-9a-zA-Z_]+]] = OpTypeArray [[v4float]] [[int_4096]]
// CHECK: [[ubo_struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[array]]
// CHECK: [[offset_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[ubo_struct]]
// CHECK: [[v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[float]] 2
// CHECK: [[struct_v2float:%[0-9a-zA-Z_]+]] = OpTypeStruct [[v2float]]
// CHECK: [[c_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[struct_v2float]]
// CHECK: [[runtime]] = OpTypeRuntimeArray [[v4float]]
// CHECK: [[struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[runtime]]
// CHECK: [[data_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[struct]]
// CHECK: [[ptr_uniform_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[v4float]]
// CHECK: [[zero:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 0
// CHECK: [[ptr_uniform_v2float:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[v2float]]
// CHECK: [[ptr_storagebuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[v4float]]
// CHECK: [[float_zero:%[0-9a-zA-Z_]+]] = OpConstant [[float]] 0
// CHECK: [[image_var]] = OpVariable [[image_ptr]] UniformConstant
// CHECK: [[sampler_var]] = OpVariable [[sampler_ptr]] UniformConstant
// CHECK: [[offset_var]] = OpVariable [[offset_ptr]] Uniform
// CHECK: [[c_var]] = OpVariable [[c_ptr]] Uniform
// CHECK: [[data_var]] = OpVariable [[data_ptr]] StorageBuffer
// CHECK: [[load_image:%[0-9a-zA-Z_]+]] = OpLoad [[image]] [[image_var]]
// CHECK: [[load_sampler:%[0-9a-zA-Z_]+]] = OpLoad [[sampler]] [[sampler_var]]
// CHECK: [[offset_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[ptr_uniform_v4float]] [[offset_var]] [[zero]] [[zero]]
// CHECK: [[c_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[ptr_uniform_v2float]] [[c_var]] [[zero]]
// CHECK: [[load_c:%[0-9a-zA-Z_]+]] = OpLoad [[v2float]] [[c_gep]]
// CHECK: [[data_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[ptr_storagebuffer_v4float]] [[data_var]] [[zero]] [[zero]]
// CHECK: [[sampled:%[0-9a-zA-Z_]+]] = OpSampledImage [[sampled_image]] [[load_image]] [[load_sampler]]
// CHECK: [[sample:%[0-9a-zA-Z_]+]] = OpImageSampleExplicitLod [[v4float]] [[sampled]] [[load_c]] Lod [[float_zero]]
// CHECK: [[offset_load:%[0-9a-zA-Z_]+]] = OpLoad [[v4float]] [[offset_gep]]
// CHECK: [[add:%[0-9a-zA-Z_]+]] = OpFAdd [[v4float]] [[sample]] [[offset_load]]
// CHECK: OpStore [[data_gep]] [[add]]
