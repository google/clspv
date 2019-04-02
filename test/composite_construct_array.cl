// Test rewriting complete sets of insertions into an array.
// The rewrite is done by default.

// RUN: clspv %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

struct S { int arr[5]; };

struct S bar(int n) {
  struct S s;
  if (n > 0) {
    s.arr[0] = n;
    s.arr[1] = n + 1;
    s.arr[2] = n + 2;
    s.arr[3] = n + 3;
    s.arr[4] = n + 4;
  }
  return s;
}
kernel void foo(global struct S *out, int n) {
  *out = bar(n);
}

// CHECK: [[array:%[0-9a-zA-Z_]+]] = OpTypeArray
// CHECK: [[struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[array]]
// CHECK-NOT: OpCompositeInsert
// CHECK: [[array_construct:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[array]]
// CHECK-NOT: OpCompositeInsert
// CHECK: [[struct_construct:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[struct]]
// CHECK-NOT: OpCompositeInsert
