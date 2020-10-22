// RUN: clspv %s -o %t.spv -no-inline-single -no-dra
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

static float foo(__global float* data) {
  return data[0];
}

static float bar(__constant float* data) {
  return data[0];
}

kernel void baz(__global float* in1, __constant float* in2, __global float* out) {
  out[0] = foo(in1);
  out[1] = bar(in2);
}

// #651: Since __constant and __global are both mapped to StorageBuffer storage
// class, ensure the function type for the helpers is correctly unique.
//
// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[ptr_ssbo_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[float]]
// CHECK: OpTypeFunction [[float]] [[ptr_ssbo_float]]
// CHECK-NOT: OpTypeFunction [[float]] [[ptr_ssbo_float]]
