// RUN: clspv -samplermap=%S/issue-157.samplermap %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[double:[0-9a-zA-Z_]+]] = OpTypeFloat 64
// CHECK-DAG: %[[float_0:[0-9a-zA-Z_]+]] = OpConstant %[[float]] 0
// CHECK-DAG: %[[double_0_050000000000000003:[0-9a-zA-Z_]+]] = OpConstant %[[double]] 0.050000000000000003
// CHECK-DAG: %[[float_100:[0-9a-zA-Z_]+]] = OpConstant %[[float]] 100

const sampler_t sampler =
CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_REPEAT | CLK_FILTER_NEAREST;

kernel void foo(global float* out,
                global float* in,
                __read_only image2d_t inImage) {
  uint i = get_global_id(0);
  float sum = 0.0f;
  for (int j = 0; j < 4;++j)
    sum += read_imagef(inImage, sampler, (float2)(0.05 * (float)i, 0.05 * (float)i))[j];
  out[i] = in[i] + 100.0f * sum;
}

