// RUN: clspv %s -o %t.spv --cl-std=CL2.0 --inline-entry-points
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(write_only image2d_t im) { }

kernel void bar(read_write image2d_t im) { }
