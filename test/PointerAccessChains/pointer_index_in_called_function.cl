// RUN: clspv %s -o %t.spv -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -no-dra -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm -check-prefix=NODRA
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct {
  float x[12];
} Thing;

__attribute__((noinline))
float bar(global Thing* a, int n) {
  return a[n].x[7];
}

void kernel __attribute__((reqd_work_group_size(1, 1, 1)))
foo(global Thing* a, global float *b, int n) {
  *b = bar(a, n);
}

// Direct-resource-access optimization converts to straight OpAccessChain

// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_uint_12:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 12
// CHECK-DAG:  [[__arr_float_uint_12:%[0-9a-zA-Z_]+]] = OpTypeArray [[_float]] [[_uint_12]]
// CHECK-DAG:  [[__struct_5:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__arr_float_uint_12]]
// CHECK-DAG:  [[__runtimearr__struct_5:%[0-9a-zA-Z_]+]] = OpTypeRuntimeArray [[__struct_5]]
// CHECK-DAG:  [[__struct_7:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__runtimearr__struct_5]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK-DAG:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG:  [[_uint_7:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 7
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpFunction
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_22]] [[_uint_0]] [[_27]] [[_uint_0]] [[_uint_7]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_29]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpFunction
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_5]] [[_22]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_25]] [[_33]] [[_36]]



// NODRA-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// NODRA-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// NODRA-DAG:  [[_uint_12:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 12
// NODRA-DAG:  [[__arr_float_uint_12:%[0-9a-zA-Z_]+]] = OpTypeArray [[_float]] [[_uint_12]]
// NODRA-DAG:  [[__struct_5:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__arr_float_uint_12]]
// NODRA-DAG:  [[__runtimearr__struct_5:%[0-9a-zA-Z_]+]] = OpTypeRuntimeArray [[__struct_5]]
// NODRA-DAG:  [[__struct_7:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__runtimearr__struct_5]]
// NODRA-DAG:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// NODRA-DAG:  [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// NODRA-DAG:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// NODRA-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// NODRA-DAG:  [[_uint_7:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 7
// NODRA:  [[_22:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// NODRA:  [[_25:%[0-9a-zA-Z_]+]] = OpFunction
// NODRA:  [[_26:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer__struct_5]]
// NODRA:  [[_27:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// NODRA:  [[_29:%[0-9a-zA-Z_]+]] = OpPtrAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_27]] [[_uint_0]] [[_uint_7]]
// NODRA:  [[_30:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_29]]
// NODRA:  [[_31:%[0-9a-zA-Z_]+]] = OpFunction
// NODRA:  [[_32:%[0-9a-zA-Z_]+]] = OpLabel
// NODRA:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_5]] [[_22]] [[_uint_0]] [[_uint_0]]
// NODRA:  [[_36:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]]
// NODRA:  [[_37:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_25]] [[_33]] [[_36]]
