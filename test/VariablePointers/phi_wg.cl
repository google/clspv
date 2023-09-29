// RUN: clspv %target %s -o %t.spv -no-dra -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Despite choice against null, workgroup requires full VariablePointers.
kernel void foo(local int* in, global int* out, int a) {
  if (a == 0) {
    barrier(CLK_GLOBAL_MEM_FENCE);
    *out = *in;
  } else {
    local int* x = 0;
    *out = *x;
  }
}

// CHECK-NOT: OpCapability VariablePointersStorageBuffer
// CHECK: OpCapability VariablePointers
// CHECK-NOT: StorageBuffer
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Workgroup [[uint]]
// CHECK: OpPhi [[ptr]]


