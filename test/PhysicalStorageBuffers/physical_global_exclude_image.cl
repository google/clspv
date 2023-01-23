// RUN: clspv %s -o %t.spv -arch=spir64 -physical-storage-buffers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that images and samplers are excluded from physical pointer
// transformation even though they are pointers in the global address space
kernel void test(read_only image2d_t srcimg, global float4 *dst, sampler_t sampler)
{
    int    tid_x = get_global_id(0);
    int    tid_y = get_global_id(1);
    int    indx = tid_y * get_image_width(srcimg) + tid_x;
    float4 color;

    dst[indx] = read_imagef(srcimg, sampler, (int2)(tid_x, tid_y));
}

// CHECK: [[clspv_reflection:%[0-9a-zA-Z_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"
// CHECK: [[void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: OpExtInst [[void]] [[clspv_reflection]] ArgumentSampledImage
// CHECK-DAG: OpExtInst [[void]] [[clspv_reflection]] ArgumentSampler
// CHECK-DAG: OpExtInst [[void]] [[clspv_reflection]] ArgumentPointerPushConstant

