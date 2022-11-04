// RUN: clspv %target %s -o %t.spv -cluster-pod-kernel-args
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float* A, float f, float g) {
  *A = f + g;
}

kernel void bar(global float* B, float f, float g) {
  *B = f - g;
}

// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[__runtimearr_float:%[a-zA-Z0-9_]+]] = OpTypeRuntimeArray [[_float]]
// CHECK-DAG: [[__struct_4:%[a-zA-Z0-9_]+]] = OpTypeStruct [[__runtimearr_float]]
// CHECK-DAG: [[__struct_6:%[a-zA-Z0-9_]+]] = OpTypeStruct [[_float]] [[_float]]
// CHECK-DAG: [[__struct_7:%[a-zA-Z0-9_]+]] = OpTypeStruct [[__struct_6]]
// The { float float } struct type only occurs once
// CHECK-NOT:  OpTypeStruct [[_float]] [[_float]]
