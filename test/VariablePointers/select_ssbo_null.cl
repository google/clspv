// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Only requires VariablePointersStorageBuffer because of selection against null.
kernel void foo(global int* in, global int* out, int a) {
  global int* x = (a == 0) ? in : 0;
  *out = *x;
}

// CHECK-NOT: OpCapability VariablePointers
// CHECK: OpCapability VariablePointersStorageBuffer
// CHECK-NOT: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uint]]
// CHECK: OpSelect [[ptr]]
