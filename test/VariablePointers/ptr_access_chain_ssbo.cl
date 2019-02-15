// RUN: clspv %s -S -o %t.spvasm -no-dra -no-inline-single
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -no-dra -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// The OpPtrAccessChain requires VariablePointersStorageBuffer. So does passing
// the of the argument though...
int bar(global int* x) { return x[1]; }
kernel void foo(global int* in, global int* out) {
  *out = bar(in);
}

// CHECK-NOT: OpCapability VariablePointers
// CHECK: OpCapability VariablePointersStorageBuffer
// CHECK-NOT: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uint]]
// CHECK: OpPtrAccessChain [[ptr]]

