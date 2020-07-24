// RUN: clspv %s -o %t.spv -samplermap=%s.map
// RUN: clspv-reflection %t.spv -o %t.map
// RUN: FileCheck %s < %t.map

// RUN: clspv %s -o %t2.spv -samplermap=%s.map
// RUN: clspv-reflection %t2.spv -o %t2.map
// RUN: FileCheck %s < %t2.map
//
// CHECK: samplerExpr
// CHECK-NOT: samplerExpr

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
