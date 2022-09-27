// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Requires full variable pointers because the selection is between different
// objects.
kernel void foo(global int* in1, global int* in2, global int* out, int a) {
  global int* x = (a == 0) ? in1 : in2;
  *out = *x;
}

// CHECK-NOT: StorageBuffer
// CHECK: OpCapability VariablePointersStorageBuffer
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uint]]
// CHECK: OpSelect [[ptr]]
