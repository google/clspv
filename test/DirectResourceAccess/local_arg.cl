// RUN: clspv %s -o %t.spv -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Just for fun, swap arguments in the helpers.

void core(global int *A, int n, local int *B) { A[n] = B[n + 2]; }

void apple(local int *B, global int *A, int n) { core(A, n + 1, B); }

kernel void foo(global int *A, int n, local int *B) { apple(B, A, n); }

kernel void bar(global int *A, int n, local int *B) { apple(B, A, n); }
// CHECK:      OpEntryPoint GLCompute [[_52:%[0-9a-zA-Z_]+]] "foo"
// CHECK:      OpEntryPoint GLCompute [[_58:%[0-9a-zA-Z_]+]] "bar"
// CHECK:      OpDecorate [[_33:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:      OpDecorate [[_33]] Binding 0
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:      [[_33]] = OpVariable {{.*}} StorageBuffer
// CHECK-DAG:      [[_1:%[0-9a-zA-Z_]+]] = OpVariable {{.*}} Workgroup
// CHECK:      [[_35:%[0-9a-zA-Z_]+]] = OpFunction [[_void]]
// CHECK:      [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_1]]
// CHECK:      [[_43:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_33]]
// CHECK:      [[_44:%[0-9a-zA-Z_]+]] = OpFunction [[_void]]
// CHECK:      [[_49:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_33]]
// CHECK:      [[_n45:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_1]]
// CHECK:      [[_51:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_35]] [[_49]] {{.*}} [[_n45]]
// CHECK:      [[_52]] = OpFunction [[_void]]
// CHECK:      [[_5:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_1]]
// CHECK:      [[_54:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_33]]
// CHECK:      [[_57:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_44]] [[_5]] [[_54]]
// CHECK:      [[_58]] = OpFunction [[_void]]
// CHECK:      [[_10:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_1]]
// CHECK:      [[_60:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_33]]
// CHECK:      [[_63:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_44]] [[_10]] [[_60]]
