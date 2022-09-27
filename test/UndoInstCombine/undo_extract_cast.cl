// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv --enable-opaque-pointers
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-NOT: OpTypeVector {{.*}} 16

__kernel void test_r_uint8(read_only image2d_t srcimg, __global unsigned char *dst, sampler_t sampler)
{
    int    tid_x = get_global_id(0);
    int    tid_y = get_global_id(1);
    int    indx = tid_y * get_image_width(srcimg) + tid_x;
    uint4    color;

    color = read_imageui(srcimg, sampler, (int2)(tid_x, tid_y));
    dst[indx] = (unsigned char)(color.x);

}

