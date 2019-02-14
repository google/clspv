// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Same object selection only requires VariablePointersStorageBuffer.
kernel void foo(global int* in, global int* out, int a) {
  global int* x = in + 1;
  global int* y = in + 2;
  global int* z = (a == 0) ? x : y;
  *out = *z;
}

// CHECK-NOT: OpCapability VariablePointers
// CHECK: OpCapability VariablePointersStorageBuffer
// CHECK-NOT: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uint]]
// CHECK: OpSelect [[ptr]]
