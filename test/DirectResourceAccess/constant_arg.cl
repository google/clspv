// RUN: clspv %s -o %t.spv -no-inline-single -keep-unused-arguments -cluster-pod-kernel-args=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Just for fun, swap arguments in the helpers.

void core(global int *A, int n, constant int *B) { A[n] = B[n + 2]; }

void apple(constant int *B, global int *A, int n) { core(A, n + 1, B); }

kernel void foo(global int *A, int n, constant int *B) { apple(B, A, n); }

kernel void bar(global int *A, int n, constant int *B) { apple(B, A, n); }
// CHECK:  OpEntryPoint GLCompute [[_43:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_50:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_22]] Binding 0
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_23]] Binding 2
// CHECK:  OpDecorate [[_23]] NonWritable
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_22]] = OpVariable {{.*}} StorageBuffer
// CHECK-DAG:  [[_23]] = OpVariable {{.*}} StorageBuffer
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpFunction [[_void]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_23]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_22]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpFunction [[_void]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_22]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_23]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_25]] [[_39]] {{.*}} [[_40]]
// CHECK:  [[_43]] = OpFunction [[_void]]
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_22]]
// CHECK:  [[_48:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_23]]
// CHECK:  [[_49:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_34]] [[_48]] [[_45]]
// CHECK:  [[_50]] = OpFunction [[_void]]
// CHECK:  [[_52:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_22]]
// CHECK:  [[_55:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_23]]
// CHECK:  [[_56:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_34]] [[_55]] [[_52]]
