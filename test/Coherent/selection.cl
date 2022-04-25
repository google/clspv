// RUN: clspv %s -o %t.spv -no-inline-single -no-dra
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Both x's should be coherent. y should not be coherent because it is not read.
__attribute__((noinline))
void bar(global int* x, int y) { *x = y; }

kernel void foo(global int* x, global int* y, int c) {
  int z = x[0];
  barrier(CLK_GLOBAL_MEM_FENCE);
  global int* ptr = c ? x : y;
  bar(ptr + 1, z);
}

// CHECK: OpDecorate [[x:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[x]] Binding 0
// CHECK: OpDecorate [[x]] Coherent
// CHECK: OpDecorate [[y:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[y]] Binding 1
// CHECK-NOT: OpDecorate [[y]] Coherent
// CHECK: OpDecorate [[param:%[a-zA-Z0-9_]+]] Coherent
// CHECK: [[param]] = OpFunctionParameter


