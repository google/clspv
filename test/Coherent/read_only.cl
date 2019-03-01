
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int *data, local int* l) {
  int x = data[0];
  barrier(CLK_GLOBAL_MEM_FENCE);
  l[0] = x;
}

// |data| is only read so is not marked as Coherent.
// CHECK-NOT: OpDecorate {{.*}} Coherent


