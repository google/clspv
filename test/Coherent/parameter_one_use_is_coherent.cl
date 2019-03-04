// RUN: clspv %s -o %t.spv -no-inline-single -no-dra
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

int bar(global int* x) { return x[0]; }

kernel void foo1(global int* data) {
  int x = bar(data);
  barrier(CLK_GLOBAL_MEM_FENCE);
  data[1] = x;
}

kernel void foo2(global int* x, global int* y) {
  int z = bar(x);
  barrier(CLK_GLOBAL_MEM_FENCE);
  y[0] = z;
}

// CHECK: OpDecorate [[var:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[var]] Binding 0
// CHECK: OpDecorate [[var]] Coherent
// CHECK: OpDecorate [[var2:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[var2]] Binding 1
// CHECK-NOT: OpDecorate [[var2]] Coherent
// CHECK: OpDecorate [[param:%[a-zA-Z0-9_]+]] Coherent
// CHECK: [[param]] = OpFunctionParameter

