// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Null pointer for SSBO requires VariablePointersStorageBuffer.
kernel void foo(global int* out, int n) {
  global int* x = 0;
  *out = *x;
}

// CHECK-NOT: OpCapability VariablePointers
// CHECK: OpCapability VariablePointersStorageBuffer
// CHECK-NOT: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uint]]
// CHECK: OpConstantNull [[ptr]]
