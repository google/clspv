// RUN: clspv %s -o %t.spv -no-inline-single -no-dra
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

int bar(global int* x) { return x[0]; }

kernel void foo(global int* data) {
  int x = bar(data);
  barrier(CLK_GLOBAL_MEM_FENCE);
  data[1] = x;
}

// CHECK: OpDecorate [[var:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[var]] Binding 0
// CHECK: OpDecorate [[var]] Coherent
// CHECK: OpDecorate [[param:%[a-zA-Z0-9_]+]] Coherent
// CHECK: [[param]] = OpFunctionParameter

