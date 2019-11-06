// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1)))
dest_is_array(global float *A, int n, int k) {
  float dest[7];
  for (int i = 0; i < 7; i++) {
    // Writing the whole array.
    dest[i] = A[i];
  }
  A[n] = dest[k];
}
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK:  [[__ptr_Function_float:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[_float]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK:  [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK:  [[_uint_6:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 6
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpVariable {{.*}} StorageBuffer
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpVariable {{.*}} Function
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_28]] [[_uint_0]]
// CHECK:  OpCopyMemory [[_34]] [[_33]] Aligned 4
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_uint_1]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_28]] [[_uint_1]]
// CHECK:  OpCopyMemory [[_36]] [[_35]] Aligned 4
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_uint_2]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_28]] [[_uint_2]]
// CHECK:  OpCopyMemory [[_38]] [[_37]] Aligned 4
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_uint_3]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_28]] [[_uint_3]]
// CHECK:  OpCopyMemory [[_40]] [[_39]] Aligned 4
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_uint_4]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_28]] [[_uint_4]]
// CHECK:  OpCopyMemory [[_42]] [[_41]] Aligned 4
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_uint_5]]
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_28]] [[_uint_5]]
// CHECK:  OpCopyMemory [[_44]] [[_43]] Aligned 4
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_uint_6]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_28]] [[_uint_6]]
// CHECK:  OpCopyMemory [[_46]] [[_45]] Aligned 4
