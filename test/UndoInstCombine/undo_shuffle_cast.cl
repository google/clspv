// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-NOT: OpTypeVector {{.*}} 16

__kernel void testReadi(read_only image2d_t srcimg, __global uchar4 *dst)
{
    int    tid_x = get_global_id(0);
    int    tid_y = get_global_id(1);
    int    indx = tid_y * get_image_width(srcimg) + tid_x;
    int4    color;

    const sampler_t sampler = CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST | CLK_NORMALIZED_COORDS_FALSE;
    color = read_imagei(srcimg, sampler, (int2)(tid_x, tid_y));
  uchar4 dst_write;
     dst_write.x = (uchar)color.x;
     dst_write.y = (uchar)color.y;
     dst_write.z = (uchar)color.z;
     dst_write.w = (uchar)color.w;
  dst[indx] = dst_write;

}

