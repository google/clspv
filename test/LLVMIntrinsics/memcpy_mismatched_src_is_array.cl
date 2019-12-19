// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv
// Issue #473: rewrite as a clspv-opt test
// XFAIL: *

void kernel __attribute__((reqd_work_group_size(1, 1, 1)))
src_is_array(global float *A, int n, int k) {
  float src[7];
  for (int i = 0; i < 7; i++) {
    src[i] = i;
  }
  for (int i = 0; i < 7; i++) {
    A[n+i] = src[i]; // Reading whole array.
  }
}
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__ptr_Function_float:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[_float]]
// CHECK-DAG:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG:  [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK-DAG:  [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK-DAG:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK-DAG:  [[_uint_6:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 6
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpVariable {{.*}} StorageBuffer
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpVariable {{.*}} Function
// CHECK:  OpStore
// CHECK:  [[_47:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_0]]
// CHECK:  [[_48:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_37:%[0-9a-zA-Z_]+]] [[_uint_0]]
// CHECK:  [[_49:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]] [[_48]]
// CHECK:  OpCopyMemory [[_49]] [[_47]] Aligned 4
// CHECK:  [[_50:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_1]]
// CHECK:  [[_51:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_37]] [[_uint_1]]
// CHECK:  [[_52:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]] [[_51]]
// CHECK:  OpCopyMemory [[_52]] [[_50]] Aligned 4
// CHECK:  [[_53:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_2]]
// CHECK:  [[_54:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_37]] [[_uint_2]]
// CHECK:  [[_55:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]] [[_54]]
// CHECK:  OpCopyMemory [[_55]] [[_53]] Aligned 4
// CHECK:  [[_56:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_3]]
// CHECK:  [[_57:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_37]] [[_uint_3]]
// CHECK:  [[_58:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]] [[_57]]
// CHECK:  OpCopyMemory [[_58]] [[_56]] Aligned 4
// CHECK:  [[_59:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_4]]
// CHECK:  [[_60:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_37]] [[_uint_4]]
// CHECK:  [[_61:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]] [[_60]]
// CHECK:  OpCopyMemory [[_61]] [[_59]] Aligned 4
// CHECK:  [[_62:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_5]]
// CHECK:  [[_63:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_37]] [[_uint_5]]
// CHECK:  [[_64:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]] [[_63]]
// CHECK:  OpCopyMemory [[_64]] [[_62]] Aligned 4
// CHECK:  [[_65:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_6]]
// CHECK:  [[_66:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_37]] [[_uint_6]]
// CHECK:  [[_67:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]] [[_66]]
// CHECK:  OpCopyMemory [[_67]] [[_65]] Aligned 4
