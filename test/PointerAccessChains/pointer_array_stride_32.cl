// RUN: clspv %s -o %t.spv -no-dra -no-inline-single
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

static double4 bar(global double4* in, int n) {
  return in[n];
}

kernel void foo(global double4* out, global double4* in, int n) {
  *out = bar(in, n);
}

// CHECK-DAG: OpDecorate [[rta_double4:%[a-zA-Z0-9_]+]] ArrayStride 32
// CHECK-DAG: OpDecorate [[ptr_double4:%[a-zA-Z0-9_]+]] ArrayStride 32
// CHECK-DAG: [[double:%[a-zA-Z0-9_]+]] = OpTypeFloat 64
// CHECK-DAG: [[double4:%[a-zA-Z0-9_]+]] = OpTypeVector [[double]] 4
// CHECK-DAG: [[rta_double4]] = OpTypeRuntimeArray [[double4]]
// CHECK-DAG: [[ptr_double4]] = OpTypePointer StorageBuffer [[double4]]
