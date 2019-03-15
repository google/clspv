// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void bar() { barrier(CLK_GLOBAL_MEM_FENCE); }

kernel void foo(global int* data) {
  int x = data[0];
  bar();
  data[1] = x;
}

// CHECK: OpDecorate [[var:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[var]] Binding 0
// CHECK: OpDecorate [[var]] Coherent
