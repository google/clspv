// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Despite same object selection, workgroup selection requires full
// VariablePointers.
kernel void foo(local int* in, global int* out, int a) {
  local int* x = in + 1;
  local int* y = in + 2;
  local int* z = (a == 0) ? x : y;
  *out = *z;
}

// CHECK-NOT: OpCapability VariablePointersStorageBuffer
// CHECK: OpCapability VariablePointers
// CHECK-NOT: StorageBuffer
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Workgroup [[uint]]
// CHECK: OpSelect [[ptr]]
