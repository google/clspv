// RUN: clspv %target %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Just for fun, swap arguments in the helpers.

__attribute__((noinline))
void core(global int *A, int n, local int *B) { A[n] = B[n + 2]; }

__attribute__((noinline))
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
// CHECK:      [[_52]] = OpFunction [[_void]]
// CHECK:      [[_57:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_44:%[0-9a-zA-Z_]+]]
// CHECK:      [[_58]] = OpFunction [[_void]]
// CHECK:      [[_63:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_44]]
// CHECK:      [[_35:%[0-9a-zA-Z_]+]] = OpFunction [[_void]]
// CHECK:      [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_1]]
// CHECK:      [[_43:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_33]]
// CHECK:      [[_44]] = OpFunction [[_void]]
// CHECK:      [[apple_param:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[_uint]]
// CHECK:      [[add:%[a-zA-Z0-9_]+]] = OpIAdd [[_uint]] [[apple_param]]
// CHECK:      [[_51:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_35]] [[add]]
