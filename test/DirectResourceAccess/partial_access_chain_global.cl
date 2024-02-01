// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// TODO(#1292)
// XFAIL: *

// Kernel |bar| does a non-trivial access chain before calling the helper.

__attribute__((noinline))
void apple(global int *A, global int *B, int n) { A[n] = B[n + 2]; }

kernel void foo(global int *A, global int *B, int n) { apple(A, B, n); }

kernel void bar(global int *A, global int *B, int n) { apple(A + 1, B, n); }
// CHECK:  OpEntryPoint GLCompute [[_33:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_40:%[0-9a-zA-Z_]+]] "bar"
// CHECK-DAG:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] Binding 1
// CHECK-DAG:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] Binding 0
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_21]] = OpVariable {{.*}} StorageBuffer
// CHECK-DAG:  [[_22]] = OpVariable {{.*}} StorageBuffer
// CHECK:  [[_33]] = OpFunction [[_void]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_22]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_24:%[0-9a-zA-Z_]+]] [[_35]]
// CHECK:  [[_40]] = OpFunction [[_void]]
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_22]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_24]] [[_45]]
// CHECK:  [[_24]] = OpFunction [[_void]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpFunctionParameter {{.*}}
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpFunctionParameter {{.*}}
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_21]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpPtrAccessChain {{.*}} [[_25]]
