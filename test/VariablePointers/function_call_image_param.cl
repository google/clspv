// RUN: clspv %s -o %t.spv -no-dra -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__attribute__((noinline))
void bar(write_only image2d_t image) {
  write_imagef(image, (int2)(0, 0), (float4)(0.0));
}

kernel void foo(write_only image2d_t image) {
  bar(image);
}

// CHECK-NOT: OpCapability VariablePointers
// CHECK-NOT: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[image:%[a-zA-Z0-9_]+]] = OpTypeImage
// CHECK: OpFunctionParameter [[image]]
