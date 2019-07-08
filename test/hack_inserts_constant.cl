// Test the -hack-inserts option.
// Check that we can remove partial chains of insertvalue
// to avoid OpCompositeInsert entirely.

// RUN: clspv %s -o %t.spv -hack-inserts -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-NOT: OpCompositeInsert
// CHECK: OpCompositeConstruct
// CHECK-NOT: OpCompositeInsert

typedef struct { float a, b, c, d; } S;

S boo(float a) {
  S result = {10.0f, 11.0f, 12.0f, 13.0f};
  result.c = a+2.0f;
  result.b = a+1.0f;
  // Skip filling in result.a, result.d
  return result;
}


kernel void foo(global S* data, float f) {
  *data = boo(f);
}


