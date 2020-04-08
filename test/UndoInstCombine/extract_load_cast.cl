// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-NOT: OpTypeVector {{.*}} 6

kernel void foo(global int *out) {
  *out = (short)get_local_size(0);
}

