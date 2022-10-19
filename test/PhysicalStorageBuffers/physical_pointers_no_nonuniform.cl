// RUN: clspv --arch=spir64 %s -o %t.spv --spv-version=1.5 --decorate-nonuniform --physical-storage-buffers
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.2spv1.5 %t.spv

// PhysicalStorageBuffer uses should not get the NonUniform decoration

// CHECK-NOT: OpCapability ShaderNonUniform
// CHECK-NOT: OpDecorate {{%[^ ]+}} NonUniform

kernel void test(global int* in, global int* outA, global int* outB) {
    size_t gid = get_global_id(0);

    global int *select_ptr = (in[gid] % 2 == 0) ? &outA[gid] : &outB[gid];
    *select_ptr = in[gid];
}
