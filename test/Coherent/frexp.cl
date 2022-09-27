// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int *data, global float* x) {
  float y = data[0];
  barrier(CLK_GLOBAL_MEM_FENCE);
  *x = frexp(y, data + 1);
}

// CHECK: OpDecorate [[data:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[data]] Binding 0
// CHECK: OpDecorate [[data]] Coherent
// CHECK: OpDecorate [[x:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[x]] Binding 1
// CHECK-NOT: OpDecorate [[x]] Coherent
