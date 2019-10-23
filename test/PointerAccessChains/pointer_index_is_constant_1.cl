// RUN: clspv %s -o %t.spv -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -no-dra -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm -check-prefix=NODRA
// RUN: spirv-val --target-env vulkan1.0 %t.spv

struct Thing
{
  float a[128];
};


float bar(global struct Thing* a)
{
  return a[1].a[5];
}


void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global struct Thing* b)
{
  *a = bar(b);
}

// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_uint_128:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 128
// CHECK-DAG:  [[__arr_float_uint_128:%[0-9a-zA-Z_]+]] = OpTypeArray [[_float]] [[_uint_128]]
// CHECK-DAG:  [[__struct_5:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__arr_float_uint_128]]
// CHECK-DAG:  [[__runtimearr__struct_5:%[0-9a-zA-Z_]+]] = OpTypeRuntimeArray [[__struct_5]]
// CHECK-DAG:  [[__struct_7:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__runtimearr__struct_5]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK-DAG:  [[__runtimearr_float:%[0-9a-zA-Z_]+]] = OpTypeRuntimeArray [[_float]]
// CHECK-DAG:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK-DAG:  [[_20:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpFunction
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_20]] [[_uint_0]] [[_uint_1]] [[_uint_0]] [[_uint_5]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_25]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpFunction
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_5]] [[_20]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_22]] [[_30]]



// NODRA-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// NODRA-DAG:  [[__runtimearr_float:%[0-9a-zA-Z_]+]] = OpTypeRuntimeArray [[_float]]
// NODRA-DAG:  [[__struct_3:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__runtimearr_float]]
// NODRA-DAG:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// NODRA-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// NODRA-DAG:  [[_uint_128:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 128
// NODRA-DAG:  [[__arr_float_uint_128:%[0-9a-zA-Z_]+]] = OpTypeArray [[_float]] [[_uint_128]]
// NODRA-DAG:  [[__struct_8:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__arr_float_uint_128]]
// NODRA-DAG:  [[__runtimearr__struct_8:%[0-9a-zA-Z_]+]] = OpTypeRuntimeArray [[__struct_8]]
// NODRA-DAG:  [[__struct_10:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__runtimearr__struct_8]]
// NODRA-DAG:  [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// NODRA-DAG:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// NODRA-DAG:  [[__ptr_StorageBuffer__struct_8:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_8]]
// NODRA:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// NODRA-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// NODRA-DAG:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// NODRA:  [[_21:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// NODRA:  [[_22:%[0-9a-zA-Z_]+]] = OpFunction
// NODRA:  [[_23:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer__struct_8]]
// NODRA:  [[_25:%[0-9a-zA-Z_]+]] = OpPtrAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_1]] [[_uint_0]] [[_uint_5]]
// NODRA:  [[_26:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_25]]
// NODRA:  [[_27:%[0-9a-zA-Z_]+]] = OpFunction
// NODRA:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_8]] [[_21]] [[_uint_0]] [[_uint_0]]
// NODRA:  [[_31:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_22]] [[_30]]
