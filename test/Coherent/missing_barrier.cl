
// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int *data) {
  data[1] = data[0];
}

// Lack of barrier means |data| is not coherent.
// CHECK-NOT: OpDecorate {{.*}} Coherent
