// RUN: clspv %target %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

int* inner(int* arr) {
  return &arr[0];
}

int* helper(int* arr) {
  return inner(arr);
}

kernel void foo(global int* A, int n) {
  int arr[2];
  arr[0] = 0;
  arr[1] = 1;
  *A = helper(arr)[n];
}


// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK:  [[__arr_uint_uint_2:%[0-9a-zA-Z_]+]] = OpTypeArray [[_uint]] [[_uint_2]]
// CHECK:  [[__ptr_Function__arr_uint_uint_2:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[__arr_uint_uint_2]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[__ptr_Function_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[_uint]]
// CHECK-64:  [[_ulong:%[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Function__arr_uint_uint_2]] Function
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]]
// CHECK-64: [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_uint]] [[_27]] [[_uint_0]]
// CHECK-32: [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_uint]] [[_27]] [[_uint_0]]
// CHECK:  OpStore [[_31]] [[_uint_0]]
// CHECK-64: [[_30_long:%[0-9a-zA-Z_]+]] = OpSConvert [[_ulong]] [[_30]]
// CHECK-64:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_uint]] [[_27]] [[_30_long]]
// CHECK-32:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_uint]] [[_27]] [[_30]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_33]]
// CHECK:  OpStore {{.*}} [[_34]]
