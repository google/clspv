// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Null pointer in workgroup requires VariablePointers.
kernel void foo(global int* out) {
  local int* x = 0;
  *out = *x;
}

// CHECK-NOT: OpCapability VariablePointersStorageBuffer
// CHECK: OpCapability VariablePointers
// CHECK-NOT: StorageBuffer
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Workgroup [[uint]]
// CHECK: OpConstantNull [[ptr]]
