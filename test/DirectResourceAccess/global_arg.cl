// RUN: clspv %target %s -o %t.spv -no-inline-single -cluster-pod-kernel-args=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Just for fun, swap arguments in the helpers.

__attribute__((noinline))
void core(global int *A, int n, global int *B) { A[n] = B[n + 2]; }

__attribute__((noinline))
void apple(global int *B, global int *A, int n) { core(A, n + 1, B); }

kernel void foo(global int *A, int n, global int *B) { apple(B, A, n); }

kernel void bar(global int *A, int n, global int *B) { apple(B, A, n); }
// CHECK:  OpEntryPoint GLCompute [[_43:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_50:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] Binding 0
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] Binding 2
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_22]] = OpVariable {{.*}} StorageBuffer
// CHECK-DAG:  [[_23]] = OpVariable {{.*}} StorageBuffer
// CHECK:  [[_43]] = OpFunction [[_void]]
// CHECK:  [[_49:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_34:%[a-zA-Z0-9_]+]]
// CHECK:  [[_50]] = OpFunction [[_void]]
// CHECK:  [[_56:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_34]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpFunction [[_void]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_23]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_22]]
// CHECK:  [[_34]] = OpFunction [[_void]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_25]]
