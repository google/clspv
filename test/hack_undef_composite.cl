// RUN: clspv %s -S -o %t.spvasm -hack-undef
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -hack-undef
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

struct a {
  int x;
  int y;
};

kernel void foo(global struct a* struct_out, int n) {
  struct a local_a;
  if (n == 0) {
    local_a.x = 0;
  }
  *struct_out = local_a;
}

// CHECK: [[uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[uint]] [[uint]]
// CHECK-NOT: OpUndef
// CHECK: OpConstantNull [[struct]]
// CHECK-NOT: OpUndef
