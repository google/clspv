// RUN: clspv %target %s -o %t.spv -cl-std=CL2.0 -inline-entry-points
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv --target-env vulkan1.0

kernel void foo(read_write image3d_t im) {
  int4 x = read_imagei(im, (int4)(0,0,0,0));
  write_imagei(im, (int4)(0,0,0,0), x);
}

// CHECK-DAG: OpCapability StorageImageReadWithoutFormat
// CHECK-DAG: OpCapability StorageImageWriteWithoutFormat
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint4:%[a-zA-Z0-9_]+]] = OpTypeVector [[uint]] 4
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 1
// CHECK-DAG: [[int4:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 4
// CHECK-DAG: [[coord:%[a-zA-Z0-9_]+]] = OpConstantNull [[uint4]]
// CHECK-DAG: [[image:%[a-zA-Z0-9_]+]] = OpTypeImage [[int]] 3D 0 0 0 2 Unknown
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[image]]
// CHECK: [[x:%[a-zA-Z0-9_]+]] = OpImageRead [[int4]] [[ld]] [[coord]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[uint4]] [[x]]
// CHECK: [[cast2:%[a-zA-Z0-9_]+]] = OpBitcast [[int4]] [[cast]]
// CHECK: OpImageWrite [[ld]] [[coord]] [[cast2]]

