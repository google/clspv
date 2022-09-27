// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpCapability ImageBuffer
// CHECK-DAG: OpEntryPoint GLCompute [[read_float:%[a-zA-Z0-9_]+]] "read_float"
// CHECK-DAG: OpEntryPoint GLCompute [[write_float:%[a-zA-Z0-9_]+]] "write_float"
// CHECK-DAG: OpEntryPoint GLCompute [[read_uint:%[a-zA-Z0-9_]+]] "read_uint"
// CHECK-DAG: OpEntryPoint GLCompute [[write_uint:%[a-zA-Z0-9_]+]] "write_uint"
// CHECK-DAG: OpEntryPoint GLCompute [[read_int:%[a-zA-Z0-9_]+]] "read_int"
// CHECK-DAG: OpEntryPoint GLCompute [[write_int:%[a-zA-Z0-9_]+]] "write_int"
// CHECK-DAG: OpEntryPoint GLCompute [[read_half:%[a-zA-Z0-9_]+]] "read_half"
// CHECK-DAG: OpEntryPoint GLCompute [[write_half:%[a-zA-Z0-9_]+]] "write_half"
// CHECK-DAG: OpEntryPoint GLCompute [[image_width:%[a-zA-Z0-9_]+]] "image_width"

// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[float4:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint4:%[a-zA-Z0-9_]+]] = OpTypeVector [[uint]] 4
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 1
// CHECK-DAG: [[int4:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 4
// CHECK-DAG: [[half:%[a-zA-Z0-9_]+]] = OpTypeFloat 16
// CHECK-DAG: [[half4:%[a-zA-Z0-9_]+]] = OpTypeVector [[half]] 4

// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0

// CHECK-DAG: [[f_image_ro:%[a-zA-Z0-9_]+]] = OpTypeImage [[float]] Buffer 0 0 0 1 Unknown
// CHECK-DAG: [[u_image_ro:%[a-zA-Z0-9_]+]] = OpTypeImage [[uint]] Buffer 0 0 0 1 Unknown
// CHECK-DAG: [[i_image_ro:%[a-zA-Z0-9_]+]] = OpTypeImage [[int]] Buffer 0 0 0 1 Unknown
// CHECK-DAG: [[f_image_wo:%[a-zA-Z0-9_]+]] = OpTypeImage [[float]] Buffer 0 0 0 2 Unknown
// CHECK-DAG: [[u_image_wo:%[a-zA-Z0-9_]+]] = OpTypeImage [[uint]] Buffer 0 0 0 2 Unknown
// CHECK-DAG: [[i_image_wo:%[a-zA-Z0-9_]+]] = OpTypeImage [[int]] Buffer 0 0 0 2 Unknown

// CHECK: [[read_float]] = OpFunction
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpLoad [[f_image_ro]]
// CHECK: OpImageFetch [[float4]] [[image]] [[uint_0]]
kernel void read_float(read_only image1d_buffer_t image, global float4* out) {
  out[0] = read_imagef(image, 0);
}

// CHECK: [[write_float]] = OpFunction
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpLoad [[f_image_wo]]
// CHECK: OpImageWrite [[image]]
kernel void write_float(write_only image1d_buffer_t image) {
  write_imagef(image, 0, (float4)(0));
}

// CHECK: [[read_uint]] = OpFunction
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpLoad [[u_image_ro]]
// CHECK: OpImageFetch [[uint4]] [[image]] [[uint_0]]
kernel void read_uint(read_only image1d_buffer_t image, global uint4* out) {
  out[0] = read_imageui(image, 0);
}

// CHECK: [[write_uint]] = OpFunction
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpLoad [[u_image_wo]]
// CHECK: OpImageWrite [[image]]
kernel void write_uint(write_only image1d_buffer_t image) {
  write_imageui(image, 0, (uint4)(0));
}

// CHECK: [[read_int]] = OpFunction
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpLoad [[i_image_ro]]
// CHECK: [[read:%[a-zA-Z0-9_]+]] = OpImageFetch [[int4]] [[image]] [[uint_0]]
// CHECK: OpBitcast [[uint4]] [[read]]
kernel void read_int(read_only image1d_buffer_t image, global int4* out) {
  out[0] = read_imagei(image, 0);
}

// CHECK: [[write_int]] = OpFunction
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpLoad [[i_image_wo]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[int4]]
// CHECK: OpImageWrite [[image]] {{.*}} [[cast]]
kernel void write_int(write_only image1d_buffer_t image) {
  write_imagei(image, 0, (int4)(0));
}

// CHECK: [[read_half]] = OpFunction
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpLoad [[f_image_ro]]
// CHECK: [[read:%[a-zA-Z0-9_]+]] = OpImageFetch [[float4]] [[image]] [[uint_0]]
// CHECK: OpFConvert [[half4]] [[read]]
kernel void read_half(read_only image1d_buffer_t image, global half4* out) {
  out[0] = read_imageh(image, 0);
}

// CHECK: [[write_half]] = OpFunction
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpLoad [[f_image_wo]]
// CHECK: OpImageWrite [[image]]
kernel void write_half(write_only image1d_buffer_t image) {
  write_imageh(image, 0, (half4)(0));
}

// CHECK: [[image_width]] = OpFunction
// CHECK: [[ro_image:%[a-zA-Z0-9_]+]] = OpLoad [[f_image_ro]]
// CHECK: [[wo_image:%[a-zA-Z0-9_]+]] = OpLoad [[f_image_wo]]
// CHECK: [[query:%[a-zA-Z0-9_]+]] = OpImageQuerySize [[uint]] [[ro_image]]
// CHECK: [[query:%[a-zA-Z0-9_]+]] = OpImageQuerySize [[uint]] [[wo_image]]
kernel void image_width(image1d_buffer_t ri, write_only image1d_buffer_t wi, global int* out) {
  out[0] = get_image_width(ri);
  out[1] = get_image_width(wi);
}
