// RUN: clspv %target %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -no-dra -no-inline-single -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm -check-prefix=NODRA
// RUN: spirv-val --target-env vulkan1.0 %t.spv


struct Thing
{
  float a[128];
};


__attribute__((noinline))
float bar(global struct Thing* a)
{
  return a[1].a[5];
}


void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global struct Thing* b)
{
  *a = bar(b);
}

// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[_runtimearr_float:[0-9a-zA-Z_]+]] = OpTypeRuntimeArray %[[float]]
// CHECK-DAG: %[[_struct_3:[0-9a-zA-Z_]+]] = OpTypeStruct %[[_runtimearr_float]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_3:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_3]]
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[_ptr_StorageBuffer_float:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[float]]
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uint_133:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 133
// CHECK-DAG: %[[_5:[0-9]+]] = OpVariable %[[_ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK-DAG: %[[_6:[0-9]+]] = OpVariable %[[_ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:     %[[_9:[0-9]+]] = OpFunction %[[void]]
// CHECK:     %[[_14:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_float]] %[[_5]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[_15:[0-9]+]] = OpFunctionCall %[[float]] %[[_17:[0-9]+]]
// CHECK:     OpStore %[[_14]] %[[_15]]
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd
// CHECK:     %[[_17]] = OpFunction %[[float]]
// CHECK:     %[[_20:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_float]] %[[_6]] %[[uint_0]] %[[uint_133]]
// CHECK:     %[[_21:[0-9]+]] = OpLoad %[[float]] %[[_20]]
// CHECK:     OpReturnValue %[[_21]]
// CHECK:     OpFunctionEnd


// NODRA-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// NODRA-DAG: %[[_runtimearr_float:[0-9a-zA-Z_]+]] = OpTypeRuntimeArray %[[float]]
// NODRA-DAG: %[[_struct_3:[0-9a-zA-Z_]+]] = OpTypeStruct %[[_runtimearr_float]]
// NODRA-DAG: %[[_ptr_StorageBuffer__struct_3:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_3]]
// NODRA-DAG: %[[_ptr_StorageBuffer_float:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[float]]
// NODRA-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// NODRA-DAG: %[[uint_133:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 133
// NODRA-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// NODRA-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// NODRA-DAG: %[[uint_1:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1
// NODRA-DAG: %[[_5:[0-9]+]] = OpVariable %[[_ptr_StorageBuffer__struct_3]] StorageBuffer
// NODRA-DAG: %[[_6:[0-9]+]] = OpVariable %[[_ptr_StorageBuffer__struct_3]] StorageBuffer
// NODRA:     %[[_9:[0-9]+]] = OpFunction %[[float]]
// NODRA:     %[[_10:[0-9]+]] = OpFunctionParameter %[[_ptr_StorageBuffer_float]]
// NODRA:     %[[_11:[0-9]+]] = OpLabel
// NODRA:     %[[_14:[0-9]+]] = OpPtrAccessChain %[[_ptr_StorageBuffer_float]] %[[_10]] %[[uint_133]]
// NODRA:     %[[_15:[0-9]+]] = OpLoad %[[float]] %[[_14]]
// NODRA:     OpReturnValue %[[_15]]
// NODRA:     OpFunctionEnd
// NODRA:     %[[_18:[0-9]+]] = OpFunction %[[void]]
// NODRA:     %[[_19:[0-9]+]] = OpLabel
// NODRA:     %[[_21:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_float]] %[[_5]] %[[uint_0]] %[[uint_0]]
// NODRA:     %[[_22:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_float]] %[[_6]] %[[uint_0]] %[[uint_0]]
// NODRA:     %[[_23:[0-9]+]] = OpFunctionCall %[[float]] %[[_9]] %[[_22]]
// NODRA:     OpStore %[[_21]] %[[_23]]
// NODRA:     OpReturn
// NODRA:     OpFunctionEnd
