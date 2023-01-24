// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv

// CHECK: [[import:%[a-zA-Z0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.
// CHECK-NOT: OpExtInst {{%.*}} [[import]] Argument
// CHECK: OpExtInst {{%.*}} [[import]] ArgumentInfo
// CHECK: OpExtInst {{%.*}} [[import]] ArgumentStorageBuffer
// CHECK-NOT: OpExtInst {{%.*}} [[import]] Argument

kernel void test(global int* in, global int* out) {
  *out = 0;
}
