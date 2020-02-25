// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: OpEntryPoint GLCompute [[read_float:%[a-zA-Z0-9_]+]] "read_float"
// CHECK-DAG: OpEntryPoint GLCompute [[write_float:%[a-zA-Z0-9_]+]] "write_float"
// CHECK-DAG: OpEntryPoint GLCompute [[read_uint:%[a-zA-Z0-9_]+]] "read_uint"
// CHECK-DAG: OpEntryPoint GLCompute [[write_uint:%[a-zA-Z0-9_]+]] "write_uint"
// CHECK-DAG: OpEntryPoint GLCompute [[read_int:%[a-zA-Z0-9_]+]] "read_int"
// CHECK-DAG: OpEntryPoint GLCompute [[write_int:%[a-zA-Z0-9_]+]] "write_int"
// CHECK-DAG: OpEntryPoint GLCompute [[read_half:%[a-zA-Z0-9_]+]] "read_half"
// CHECK-DAG: OpEntryPoint GLCompute [[write_half:%[a-zA-Z0-9_]+]] "write_half"
// CHECK-DAG: OpEntryPoint GLCompute [[image_width:%[a-zA-Z0-9_]+]] "image_width"
// CHECK-DAG: OpEntryPoint GLCompute [[image_height:%[a-zA-Z0-9_]+]] "image_height"
// CHECK-DAG: OpEntryPoint GLCompute [[image_dim:%[a-zA-Z0-9_]+]] "image_dim"

// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[float4:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint3:%[a-zA-Z0-9_]+]] = OpTypeVector [[uint]] 3
// CHECK-DAG: [[uint4:%[a-zA-Z0-9_]+]] = OpTypeVector [[uint]] 4
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 1
// CHECK-DAG: [[int4:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 4
// CHECK-DAG: [[half:%[a-zA-Z0-9_]+]] = OpTypeFloat 16
// CHECK-DAG: [[half4:%[a-zA-Z0-9_]+]] = OpTypeVector [[half]] 4

// CHECK-DAG: [[float_0:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 0
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0

// CHECK-DAG: [[f_ro_image:%[a-zA-Z0-9_]+]] = OpTypeImage [[float]] 2D 0 1 0 1 Unknown
// CHECK-DAG: [[f_wo_image:%[a-zA-Z0-9_]+]] = OpTypeImage [[float]] 2D 0 1 0 2 Unknown
// CHECK-DAG: [[u_ro_image:%[a-zA-Z0-9_]+]] = OpTypeImage [[uint]] 2D 0 1 0 1 Unknown
// CHECK-DAG: [[u_wo_image:%[a-zA-Z0-9_]+]] = OpTypeImage [[uint]] 2D 0 1 0 2 Unknown
// CHECK-DAG: [[i_ro_image:%[a-zA-Z0-9_]+]] = OpTypeImage [[int]] 2D 0 1 0 1 Unknown
// CHECK-DAG: [[i_wo_image:%[a-zA-Z0-9_]+]] = OpTypeImage [[int]] 2D 0 1 0 2 Unknown
// CHECK-DAG: [[f_sampled:%[a-zA-Z0-9_]+]] = OpTypeSampledImage [[f_ro_image]]
// CHECK-DAG: [[u_sampled:%[a-zA-Z0-9_]+]] = OpTypeSampledImage [[u_ro_image]]
// CHECK-DAG: [[i_sampled:%[a-zA-Z0-9_]+]] = OpTypeSampledImage [[i_ro_image]]

// CHECK: [[read_float]] = OpFunction
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpLoad [[f_ro_image]]
// CHECK: [[sample:%[a-zA-Z0-9_]+]] = OpSampledImage [[f_sampled]] [[image]]
// CHECK: OpImageSampleExplicitLod [[float4]] [[sample]] {{.*}} Lod [[float_0]]
// CHECK: [[sample:%[a-zA-Z0-9_]+]] = OpSampledImage [[f_sampled]] [[image]]
// CHECK: OpImageSampleExplicitLod [[float4]] [[sample]] {{.*}} Lod [[float_0]]
// CHECK: OpImageFetch [[float4]] [[image]] {{.*}} Lod [[uint_0]]
kernel void read_float(read_only image2d_array_t image, sampler_t s, global float4* out) {
  out[0] = read_imagef(image, s, (float4)(0));
  out[1] = read_imagef(image, s, (int4)(0));
  out[2] = read_imagef(image, (int4)(0));
}

// CHECK: [[write_float]] = OpFunction
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpLoad [[f_wo_image]]
// CHECK: OpImageWrite [[image]]
kernel void write_float(write_only image2d_array_t image) {
  write_imagef(image, (int4)(0), (float4)(0));
}

// CHECK: [[read_uint]] = OpFunction
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpLoad [[u_ro_image]]
// CHECK: [[sample:%[a-zA-Z0-9_]+]] = OpSampledImage [[u_sampled]] [[image]]
// CHECK: OpImageSampleExplicitLod [[uint4]] [[sample]] {{.*}} Lod [[float_0]]
// CHECK: [[sample:%[a-zA-Z0-9_]+]] = OpSampledImage [[u_sampled]] [[image]]
// CHECK: OpImageSampleExplicitLod [[uint4]] [[sample]] {{.*}} Lod [[float_0]]
// CHECK: OpImageFetch [[uint4]] [[image]] {{.*}} Lod [[uint_0]]
kernel void read_uint(read_only image2d_array_t image, sampler_t s, global uint4* out) {
  out[0] = read_imageui(image, s, (float4)(0));
  out[1] = read_imageui(image, s, (int4)(0));
  out[2] = read_imageui(image, (int4)(0));
}

// CHECK: [[write_uint]] = OpFunction
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpLoad [[u_wo_image]]
// CHECK: OpImageWrite [[image]]
kernel void write_uint(write_only image2d_array_t image) {
  write_imageui(image, (int4)(0), (uint4)(0));
}

// CHECK: [[read_int]] = OpFunction
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpLoad [[i_ro_image]]
// CHECK: [[sample:%[a-zA-Z0-9_]+]] = OpSampledImage [[i_sampled]] [[image]]
// CHECK: [[read:%[a-zA-Z0-9_]+]] = OpImageSampleExplicitLod [[int4]] [[sample]] {{.*}} Lod [[float_0]]
// CHECK: OpBitcast [[uint4]] [[read]]
// CHECK: [[sample:%[a-zA-Z0-9_]+]] = OpSampledImage [[i_sampled]] [[image]]
// CHECK: [[read:%[a-zA-Z0-9_]+]] = OpImageSampleExplicitLod [[int4]] [[sample]] {{.*}} Lod [[float_0]]
// CHECK: OpBitcast [[uint4]] [[read]]
// CHECK: [[read:%[a-zA-Z0-9_]+]] = OpImageFetch [[int4]] [[image]] {{.*}} Lod [[uint_0]]
// CHECK: OpBitcast [[uint4]] [[read]]
kernel void read_int(read_only image2d_array_t image, sampler_t s, global int4* out) {
  out[0] = read_imagei(image, s, (float4)(0));
  out[1] = read_imagei(image, s, (int4)(0));
  out[2] = read_imagei(image, (int4)(0));
}

// CHECK: [[write_int]] = OpFunction
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpLoad [[i_wo_image]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[int4]]
// CHECK: OpImageWrite [[image]] {{.*}} [[cast]]
kernel void write_int(write_only image2d_array_t image) {
  write_imagei(image, (int4)(0), (int4)(0));
}

// CHECK: [[read_half]] = OpFunction
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpLoad [[f_ro_image]]
// CHECK: [[sample:%[a-zA-Z0-9_]+]] = OpSampledImage [[f_sampled]] [[image]]
// CHECK: [[read:%[a-zA-Z0-9_]+]] = OpImageSampleExplicitLod [[float4]] [[sample]] {{.*}} Lod [[float_0]]
// CHECK: OpFConvert [[half4]] [[read]]
// CHECK: [[sample:%[a-zA-Z0-9_]+]] = OpSampledImage [[f_sampled]] [[image]]
// CHECK: [[read:%[a-zA-Z0-9_]+]] = OpImageSampleExplicitLod [[float4]] [[sample]] {{.*}} Lod [[float_0]]
// CHECK: OpFConvert [[half4]] [[read]]
// CHECK: [[read:%[a-zA-Z0-9_]+]] = OpImageFetch [[float4]] [[image]] {{.*}} Lod [[uint_0]]
// CHECK: OpFConvert [[half4]] [[read]]
kernel void read_half(read_only image2d_array_t image, sampler_t s, global half4* out) {
  out[0] = read_imageh(image, s, (float4)(0));
  out[1] = read_imageh(image, s, (int4)(0));
  out[2] = read_imageh(image, (int4)(0));
}

// CHECK: [[write_half]] = OpFunction
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpLoad [[f_wo_image]]
// The conversion is optimized away
// CHECK: OpImageWrite [[image]]
kernel void write_half(write_only image2d_array_t image) {
  write_imageh(image, (int4)(0), (half4)(0));
}

// CHECK: [[image_width]] = OpFunction
// CHECK: [[ro_image:%[a-zA-Z0-9_]+]] = OpLoad [[f_ro_image]]
// CHECK: [[wo_image:%[a-zA-Z0-9_]+]] = OpLoad [[f_wo_image]]
// CHECK: [[query:%[a-zA-Z0-9_]+]] = OpImageQuerySizeLod [[uint3]] [[ro_image]] [[uint_0]]
// CHECK: OpCompositeExtract [[uint]] [[query]] 0
// CHECK: [[query:%[a-zA-Z0-9_]+]] = OpImageQuerySize [[uint3]] [[wo_image]]
// CHECK: OpCompositeExtract [[uint]] [[query]] 0
kernel void image_width(read_only image2d_array_t ri, write_only image2d_array_t wi, global int* out) {
  out[0] = get_image_width(ri);
  out[1] = get_image_width(wi);
}

// CHECK: [[image_height]] = OpFunction
// CHECK: [[ro_image:%[a-zA-Z0-9_]+]] = OpLoad [[f_ro_image]]
// CHECK: [[wo_image:%[a-zA-Z0-9_]+]] = OpLoad [[f_wo_image]]
// CHECK: [[query:%[a-zA-Z0-9_]+]] = OpImageQuerySizeLod [[uint3]] [[ro_image]] [[uint_0]]
// CHECK: OpCompositeExtract [[uint]] [[query]] 1
// CHECK: [[query:%[a-zA-Z0-9_]+]] = OpImageQuerySize [[uint3]] [[wo_image]]
// CHECK: OpCompositeExtract [[uint]] [[query]] 1
kernel void image_height(read_only image2d_array_t ri, write_only image2d_array_t wi, global int* out) {
  out[0] = get_image_height(ri);
  out[1] = get_image_height(wi);
}

// CHECK: [[image_dim]] = OpFunction
// CHECK: [[ro_image:%[a-zA-Z0-9_]+]] = OpLoad [[f_ro_image]]
// CHECK: [[wo_image:%[a-zA-Z0-9_]+]] = OpLoad [[f_wo_image]]
// CHECK: [[query:%[a-zA-Z0-9_]+]] = OpImageQuerySizeLod [[uint3]] [[ro_image]] [[uint_0]]
// CHECK: [[query:%[a-zA-Z0-9_]+]] = OpImageQuerySize [[uint3]] [[wo_image]]
kernel void image_dim(read_only image2d_array_t ri, write_only image2d_array_t wi, global int2* out) {
  out[0] = get_image_dim(ri);
  out[1] = get_image_dim(wi);
}
