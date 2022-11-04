// RUN: clspv %target %s -o %t.spv -cl-std=CL2.0 -inline-entry-points
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv --target-env vulkan1.0

kernel void foo(read_write image1d_t im) {
  float4 x = read_imagef(im, 0);
  write_imagef(im, 0, x);
}

// CHECK-DAG: OpCapability StorageImageReadWithoutFormat
// CHECK-DAG: OpCapability StorageImageWriteWithoutFormat
// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[float4:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[image:%[a-zA-Z0-9_]+]] = OpTypeImage [[float]] 1D 0 0 0 2 Unknown
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[int_0:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[image]]
// CHECK: [[x:%[a-zA-Z0-9_]+]] = OpImageRead [[float4]] [[ld]] [[int_0]]
// CHECK: OpImageWrite [[ld]] [[int_0]] [[x]]
