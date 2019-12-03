// RUN: clspv %s -o %t.spv -no-dra -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

float4 bar(read_only image2d_t image, sampler_t sampler) {
  return read_imagef(image, sampler, (float2)(0.0));
}

kernel void foo(read_only image2d_t image, sampler_t sampler, global float4* out) {
  *out = bar(image, sampler);
}

// CHECK-NOT: OpCapability VariablePointers
// CHECK-NOT: OpExtension "SPV_KHR_variable_pointers"
// CHECK-DAG: [[image:%[a-zA-Z0-9_]+]] = OpTypeImage
// CHECK-DAG: [[sampler:%[a-zA-Z0-9_]+]] = OpTypeSampler
// CHECK: OpFunctionParameter [[image]]
// CHECK: OpFunctionParameter [[sampler]]

