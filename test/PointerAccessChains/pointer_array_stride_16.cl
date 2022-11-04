// RUN: clspv %target %s -o %t.spv -no-dra -no-inline-single
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

struct A {
  float4 x;
};

struct B {
  struct A a[4];
};

__attribute__((noinline))
static float4 bar(global struct A* in, int n) {
  return in[n].x;
}

kernel void foo(global float* out, global struct B* in, int n) {
  *out = bar(&in->a[1], n)[0];
}

// CHECK-DAG: OpDecorate [[array_struct_A:%[a-zA-Z0-9_]+]] ArrayStride 16
// CHECK-DAG: OpDecorate [[ptr_struct_A:%[a-zA-Z0-9_]+]] ArrayStride 16
// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[float4:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[struct_A:%[a-zA-Z0-9_]+]] = OpTypeStruct [[float4]]
// CHECK-DAG: [[array_struct_A:%[a-zA-Z0-9_]+]] = OpTypeArray [[struct_A]]
// CHECK-DAG: [[ptr_struct_A:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[struct_A]]
