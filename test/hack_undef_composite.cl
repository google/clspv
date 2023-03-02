// RUN: clspv %target %s -o %t.spv -hack-undef
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

struct a {
  int x;
  int y;
  float arr[5];
};

kernel void foo(global struct a* struct_out, int n) {
  struct a local_a;
  if (n == 0) {
    local_a.x = 0;
  }
  *struct_out = local_a;
}

// CHECK-NOT: OpUndef
