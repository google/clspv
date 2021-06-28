// Reuse the module-scope variables we make for kernel arguments, to
// the maximum extent possible.

kernel void foo(global float* A, global float *B, global int* C, global float* D, float f, float g) {
  *A = f + g;
  *B = 0.0f;
  *C = 12;
  *D = f;
}

kernel void bar(global float* R, global float* S, global float* T, float x, float y) {
  *R = x * y;
  *S = x / y;
  *T = x;
}

// RUN: clspv %s -o %t.spv -cluster-pod-kernel-args=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -cluster-pod-kernel-args
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck -check-prefix=CLUSTER %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// In the default case:
//   R should reuse the var for A
//   S should reuse the var for B
//   T cannot reuse the var for C because of type mismatch
//   T cannot reuse the var for D because of binding mismatch
//   x cannot reuse a var because of binding mismatch
//   y should reuse the var for f

// In the cluster-pod-kernel-args case:
//   C should reuse the var for A
//   D should reuse the var for B
//   T cannot reuse the var for C because of type mismatch
//   T cannot reuse the var for D because of binding mismatch
//   {x, y} cannot reuse the var for {f, g} because of binding mismatch

// CHECK:  OpEntryPoint GLCompute [[foo:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[bar:%[0-9a-zA-Z_]+]] "bar"
// CHECK-DAG:  OpDecorate [[A_R:%[0-9a-zA-Z_]+]] Binding 0
// CHECK-DAG:  OpDecorate [[B_S:%[0-9a-zA-Z_]+]] Binding 1
// CHECK-DAG:  OpDecorate [[C:%[0-9a-zA-Z_]+]] Binding 2
// CHECK-DAG:  OpDecorate [[D:%[0-9a-zA-Z_]+]] Binding 3
// CHECK-DAG:  OpDecorate [[f_y:%[0-9a-zA-Z_]+]] Binding 4
// CHECK-DAG:  OpDecorate [[g:%[0-9a-zA-Z_]+]] Binding 5
// CHECK-DAG:  OpDecorate [[T:%[0-9a-zA-Z_]+]] Binding 2
// CHECK-DAG:  OpDecorate [[x:%[0-9a-zA-Z_]+]] Binding 3
// CHECK-NOT: OpExtension
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[__runtimearr_float:%[0-9a-zA-Z_]+]] = OpTypeRuntimeArray [[_float]]
// CHECK-DAG:  [[__struct_3:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__runtimearr_float]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[__runtimearr_uint:%[0-9a-zA-Z_]+]] = OpTypeRuntimeArray [[_uint]]
// CHECK-DAG:  [[__struct_7:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK-DAG:  [[__struct_9:%[0-9a-zA-Z_]+]] = OpTypeStruct [[_float]]
// CHECK-DAG:  [[__ptr_Uniform__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[__struct_9]]
// CHECK:  [[A_R]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[B_S]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[C]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK:  [[D]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[f_y]] = OpVariable [[__ptr_Uniform__struct_9]] Uniform
// CHECK:  [[g]] = OpVariable [[__ptr_Uniform__struct_9]] Uniform
// CHECK:  [[T]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[x]] = OpVariable [[__ptr_Uniform__struct_9]] Uniform
// CHECK:  [[foo]] = OpFunction
// CHECK:  OpAccessChain {{.*}} [[A_R]]
// CHECK:  OpAccessChain {{.*}} [[B_S]]
// CHECK:  OpAccessChain {{.*}} [[C]]
// CHECK:  OpAccessChain {{.*}} [[D]]
// CHECK:  OpAccessChain {{.*}} [[f_y]]
// CHECK:  OpAccessChain {{.*}} [[g]]
// CHECK:  [[bar]] = OpFunction
// CHECK:  OpAccessChain {{.*}} [[A_R]]
// CHECK:  OpAccessChain {{.*}} [[B_S]]
// CHECK:  OpAccessChain {{.*}} [[T]]
// CHECK:  OpAccessChain {{.*}} [[x]]
// CHECK:  OpAccessChain {{.*}} [[f_y]]

// CLUSTER:  OpEntryPoint GLCompute [[foo:%[0-9a-zA-Z_]+]] "foo"
// CLUSTER:  OpEntryPoint GLCompute [[bar:%[0-9a-zA-Z_]+]] "bar"
// CLUSTER-DAG:  OpDecorate [[A_R:%[0-9a-zA-Z_]+]] Binding 0
// CLUSTER-DAG:  OpDecorate [[B_S:%[0-9a-zA-Z_]+]] Binding 1
// CLUSTER-DAG:  OpDecorate [[C:%[0-9a-zA-Z_]+]] Binding 2
// CLUSTER-DAG:  OpDecorate [[D:%[0-9a-zA-Z_]+]] Binding 3
// CLUSTER-DAG:  OpDecorate [[T:%[0-9a-zA-Z_]+]] Binding 2
// CLUSTER-NOT: OpExtension
// CLUSTER-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CLUSTER-DAG:  [[__runtimearr_float:%[0-9a-zA-Z_]+]] = OpTypeRuntimeArray [[_float]]
// CLUSTER-DAG:  [[__struct_3:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__runtimearr_float]]
// CLUSTER-DAG:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CLUSTER-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CLUSTER-DAG:  [[__runtimearr_uint:%[0-9a-zA-Z_]+]] = OpTypeRuntimeArray [[_uint]]
// CLUSTER-DAG:  [[__struct_7:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__runtimearr_uint]]
// CLUSTER-DAG:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CLUSTER-DAG:  [[__struct_9:%[0-9a-zA-Z_]+]] = OpTypeStruct [[_float]] [[_float]]
// CLUSTER-DAG:  [[__struct_10:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__struct_9]]
// CLUSTER-DAG:  [[__ptr_PushConstant__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer PushConstant [[__struct_10]]
// CLUSTER:  [[A_R]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CLUSTER:  [[B_S]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CLUSTER:  [[C]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CLUSTER:  [[D]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CLUSTER:  [[fg:%[a-zA-Z0-9_.]+]] = OpVariable [[__ptr_PushConstant__struct_10]] PushConstant
// CLUSTER:  [[T]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CLUSTER:  [[xy:%[a-zA-Z0-9_.]+]] = OpVariable [[__ptr_PushConstant__struct_10]] PushConstant
// CLUSTER:  [[foo]] = OpFunction
// CLUSTER:  OpAccessChain {{.*}} [[A_R]]
// CLUSTER:  OpAccessChain {{.*}} [[B_S]]
// CLUSTER:  OpAccessChain {{.*}} [[C]]
// CLUSTER:  OpAccessChain {{.*}} [[D]]
// CLUSTER:  OpAccessChain {{.*}} [[fg]]
// CLUSTER:  [[bar]] = OpFunction
// CLUSTER:  OpAccessChain {{.*}} [[A_R]]
// CLUSTER:  OpAccessChain {{.*}} [[B_S]]
// CLUSTER:  OpAccessChain {{.*}} [[T]]
// CLUSTER:  OpAccessChain {{.*}} [[xy]]
