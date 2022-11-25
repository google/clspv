// RUN: clspv %s -o %t.spv -enable-printf -printf-buffer-size=128
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -enable-printf -printf-buffer-size=128 -enable-opaque-pointers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check descriptor + binding information is present and that the buffer size
// is correctly passed through

kernel void test() {
    printf("Simple printf");
}

// CHECK: %[[ReflectionImport:[0-9a-zA-Z_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"
// CHECK: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32
// CHECK: %[[uint128:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 128
// CHECK: OpExtInst %void %[[ReflectionImport]] PrintfBufferStorageBuffer %{{[0-9a-zA-Z_]+}} %{{[0-9a-zA-Z_]+}} %[[uint128]]
