// RUN: clspv %s -o %t.spv -enable-printf
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -enable-printf -enable-opaque-pointers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void test() {
    printf("Simple printf");
}

// CHECK: %[[ReflectionImport:[0-9a-zA-Z_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32
// CHECK-DAG: %[[array_ty:[0-9a-zA-Z_]+]] = OpTypeRuntimeArray %[[uint]]
// CHECK-DAG: %[[struct_ty:[0-9a-zA-Z_]+]] = OpTypeStruct %[[array_ty]]
// CHECK-DAG: %[[printf_buffer_ty:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[struct_ty]]
// CHECK-DAG: %[[zero:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[one:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1{{$}}
// CHECK-DAG: %[[string0:[0-9a-zA-Z_]+]] = OpString "Simple printf"

// Check for an allocation and for a store of 0 (i.e. the first printf id) into the buffer
// CHECK: %[[printf_buffer:[0-9a-zA-Z_]+]] = OpVariable %[[printf_buffer_ty]] StorageBuffer
// CHECK: %[[printf_buffer_access:[0-9a-zA-Z_]+]] = OpAccessChain %{{[0-9a-zA-Z_]+}} %[[printf_buffer]] %[[zero]] %[[zero]]
// CHECK: %[[printf_offset:[0-9a-zA-Z_]+]] = OpAtomicIAdd %[[uint]] %[[printf_buffer_access]] %{{[0-9a-zA-Z_]+}} %{{[0-9a-zA-Z_]+}} %[[one]]
// CHECK: %[[printf_st_offset:[0-9a-zA-Z_]+]] = OpIAdd %[[uint]] %[[printf_offset]] %[[one]]
// CHECK: %[[printf_st_access:[0-9a-zA-Z_]+]] = OpAccessChain %{{[0-9a-zA-Z_]+}} %[[printf_buffer]] %[[zero]] %[[printf_st_offset]]
// CHECK: OpStore %[[printf_st_access]] %[[zero]]

// CHECK: OpExtInst %void %[[ReflectionImport]] PrintfBufferStorageBuffer
// CHECK: OpExtInst %void %[[ReflectionImport]] PrintfInfo %[[zero]] %[[string0]]
