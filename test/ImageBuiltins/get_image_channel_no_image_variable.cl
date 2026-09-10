// RUN: clspv %target %s -o %t.spv -cl-kernel-arg-info
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

int helper(image2d_t read_only image) {
    return get_image_channel_order(image);
}

void kernel test(global int *dst, image2d_t read_only image) {
    *dst = get_image_channel_order(image);
}

void kernel test_data_type(global int *dst, image2d_t read_only image) {
    *dst = get_image_channel_data_type(image);
}

void kernel test_helper(global int *dst, image2d_t read_only image) {
    *dst = helper(image);
}

// CHECK-NOT: OpTypeImage
// CHECK-NOT: OpVariable {{.*}} UniformConstant
// CHECK-NOT: ArgumentSampledImage
// CHECK-DAG: ImageArgumentInfoChannelOrderPushConstant
// CHECK-DAG: ImageArgumentInfoChannelDataTypePushConstant
