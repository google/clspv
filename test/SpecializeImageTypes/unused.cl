// RUN: clspv %s -o %t.spv --cl-std=CL2.0 -inline-entry-points
// RUN: spirv-val %t.spv

kernel void foo(write_only image2d_t im1, read_write image2d_t im2) {
    write_imagef(im1, (int2)(0,0), (float4)(0.f,1.f,2.f,3.f));
}
