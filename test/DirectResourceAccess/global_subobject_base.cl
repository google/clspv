// RUN: clspv %s -o %t.spv -no-inline-single -keep-unused-arguments -cluster-pod-kernel-args=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// This case exercises a fix.

// The A object is complex at the kernel interface.
// But we pass down the first of the firs element of A into helper functions.
// We can still rewrite this as a direct resource access.  We have to count
// the number of GEP zeroes correctly.

typedef struct {
  int arr[12];
} S;


void core(global int *A, int n, global int *B) { A[n] = B[n + 2]; }

void apple(global int *B, global int *A, int n) { core(A, n + 1, B); }

kernel void foo(global S *A, int n, global int *B) { apple(B, &(A->arr[0]), n); }

kernel void bar(global S *A, int n, global int *B) { apple(B, A->arr, n); }

// CHECK:  OpEntryPoint GLCompute [[_49:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_56:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpDecorate [[_28:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_28]] Binding 0
// CHECK:  OpDecorate [[_29:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_29]] Binding 2
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_28]] = OpVariable {{.*}} StorageBuffer
// CHECK-DAG:  [[_29]] = OpVariable {{.*}} StorageBuffer
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpFunction [[_void]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_29]] [[_uint_0]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_28]] [[_uint_0]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpFunction [[_void]]
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_28]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_29]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_48:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_31]] [[_45]] {{.*}} [[_46]]
// CHECK:  [[_49]] = OpFunction [[_void]]
// CHECK:  [[_53:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_29]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_54:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_28]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_55:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_40]] [[_53]] [[_54]]
// CHECK:  [[_56]] = OpFunction [[_void]]
// CHECK:  [[_60:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_29]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_61:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_28]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_62:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_40]] [[_60]] [[_61]]
