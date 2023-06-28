// RUN: clspv %s -o %t.spv -enable-printf
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void test(__global int* a, __global int* b) {
    uint i = get_global_id(0);
    b[i] = a[i];
}

// CHECK: %[[ReflectionImport:[0-9a-zA-Z_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"

// CHECK-NOT: OpExtInst %void %[[ReflectionImport]] PrintfBufferStorageBuffer %{{[0-9a-zA-Z_]+}} %{{[0-9a-zA-Z_]+}} %{{[0-9a-zA-Z_]+}}
