// RUN: clspv %target -cl-std=CLC++2021 -inline-entry-points %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpSource OpenCL_CPP 202100
// CHECK: OpStore %{{[0-9]+}} %uint_202100

kernel void test(global int *x) {
    x[0] = __OPENCL_CPP_VERSION__;
}
