// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-NOT: OpCapability Int64
// CHECK: OpCompositeExtract

const sampler_t SAMPLER =
    CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP | CLK_FILTER_NEAREST;

__kernel void arg_image_to_buffer(__global float *output,
                                  __private const int count,
                                  __read_only image2d_t input) {
  int w = get_global_id(0);
  int h = get_global_id(1);

  const int offset = (w << 2);

  int2 coord = (int2)(w, h);
  float4 values = read_imagef(input, SAMPLER, coord);
  const int size = count - offset;
  if (size < 4) {
    switch (size) {
      case 3:
        output[offset+2] = values.s2;
      case 2:
        output[offset+1] = values.s1;
      case 1:
        output[offset] = values.s0;
    }
  } else {
    vstore4(values, 0, output + offset);
  }
}

