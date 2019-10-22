// RUN: clspv %s -o %t.spv -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void apple(global int *B, global int *A, int n) { A[n] = B[n + 2]; }

// foo and bar differ in the second argument, so we can't do the optimization there.

kernel void foo(global int *A, global int *B, int n) { apple(B, A, n); }

kernel void bar(global int *A, int n, global int *B) { apple(B, A, n); }
// CHECK:  OpDecorate [[_20:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_20]] Binding 0
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_20]] = OpVariable {{.*}} StorageBuffer
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpFunction [[_void]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpFunctionParameter {{.*}}
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpFunctionParameter {{.*}}
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpPtrAccessChain {{.*}} [[_26]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_20]]
