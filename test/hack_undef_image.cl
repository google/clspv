// Test the -hack-undef option, with an undef image value.
// We must keep the undef image value.
// See https://github.com/google/clspv/issues/95

// RUN: clspv %s -o %t.spv -hack-undef -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// This function takes an image argument but does not use it.
// The optimizer is smart enough to have the call pass an undef
// image operand.
float2 bar(float2 coord, read_only image2d_t im) {
  return coord + (float2)(2.5, 2.5);
}

void kernel foo(global float4* A, read_only image2d_t im, sampler_t sam, float2 coord)
{
  *A = read_imagef(im, sam, bar(coord, im));
}
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_7:%[a-zA-Z0-9_]+]] = OpTypeImage [[_float]] 2D 0 0 0 1 Unknown
// CHECK-DAG: [[_24:%[a-zA-Z0-9_]+]] = OpUndef [[_7]]
// CHECK: [[_36:%[a-zA-Z0-9_]+]] = OpFunction
// CHECK: [[_38:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[_7]]
// CHECK: [[_48:%[a-zA-Z0-9_]+]] = OpFunctionCall {{.*}} [[_36]] {{.*}} [[_24]]
