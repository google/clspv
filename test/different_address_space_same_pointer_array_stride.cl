// RUN: clspv %s -o %t.spv -no-inline-single -no-dra
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__attribute__((noinline))
static float foo(__global float* data) {
  return data[1];
}

__attribute__((noinline))
static float bar(__constant float* data) {
  return data[2];
}

kernel void baz(__global float* in1, __constant float* in2, __global float* out) {
  out[0] = foo(in1 + 1);
  out[1] = bar(in2 + 2);
}

// #651: Since __constant and __global are both mapped to StorageBuffer storage
// class, ensure the pointer parameter only receives a single array stride decoration.
//
// CHECK: OpDecorate [[rta_float:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: OpDecorate [[ptr_ssbo_float:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK-NOT: OpDecorate [[ptr_ssbo_float]] ArrayStride 4
// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[ptr_ssbo_float]] = OpTypePointer StorageBuffer [[float]]
// CHECK-DAG: [[rta_float]] = OpTypeRuntimeArray [[float]]
