// RUN: clspv -cl-std=CL3.0 -no-8bit-storage=pushconstant -no-16bit-storage=pushconstant -spv-version=1.6 -arch=spir64 -physical-storage-buffers %s -o %t.spv
// RUN: spirv-val --target-env vulkan1.3spv1.6 %t.spv

__kernel void test_vector_swizzle_xyzw(char4 value, __global char4* dst)
{
    int index = 0;
    // lvalue swizzles
    dst[index++].x = value.x;
    dst[index++].xyzw = value;
}
