// RUN: clspv %target %s -o %t.spv -no-inline-single -no-dra
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

struct Thing
{
  float a[128];
};

__attribute__((noinline))
float bar(global struct Thing* a)
{
  return a[0].a[5];
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
// CHECK-DAG:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant {{.*}} 5
// CHECK:  [[_19:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpFunction
// CHECK:  [[param:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[__ptr_StorageBuffer__struct_5]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[param]] [[_uint_0]] [[_uint_5]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_24]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpFunction
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_5]] [[_19]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_21]] [[_29]]
