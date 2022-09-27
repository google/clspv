// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


void kernel fct(global int *dst, int off, image1d_t read_only image)
{
    *dst = get_image_channel_order(image) + off;
}

// CHECK:  ImageArgumentInfoChannelOrderPushConstant {{.*}} %uint_2 %uint_4 %uint_4
