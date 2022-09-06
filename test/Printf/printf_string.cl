// RUN: clspv %s -o %t.spv -enable-printf
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -enable-printf -enable-opaque-pointers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void test() {
    printf("Hello, %s!", "world");
}

// CHECK: %[[ReflectionImport:[0-9a-zA-Z_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32
// CHECK-DAG: %[[zero:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[one:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1{{$}}
// CHECK-DAG: %[[four:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4
// CHECK-DAG: %[[string0:[0-9a-zA-Z_]+]] = OpString "Hello, %s!"
// CHECK-DAG: %[[string1:[0-9a-zA-Z_]+]] = OpString "world"

// Printf ID 0 is stored. The PrintfID 1 representing the string is stored
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[zero]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[one]]

// CHECK: OpExtInst %void %[[ReflectionImport]] PrintfBufferStorageBuffer %[[zero]] %[[zero]] %[[one]]
// CHECK: OpExtInst %void %[[ReflectionImport]] PrintfInfo %[[zero]] %[[string0]] %[[four]]
// CHECK: OpExtInst %void %[[ReflectionImport]] PrintfInfo %[[one]] %[[string1]]
