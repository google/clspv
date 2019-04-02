// RUN: clspv %s -o %t.spv -no-dra -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// VariablePointersStorageBuffer required because phi has a single buffer.
kernel void foo(global int* in, global int* out, int a) {
  if (a == 0) {
    barrier(CLK_GLOBAL_MEM_FENCE);
    *out = *in;
  } else {
    global int* x = 0;
    *out = *x;
  }
}

// CHECK-NOT: OpCapability VariablePointers
// CHECK: OpCapability VariablePointersStorageBuffer
// CHECK-NOT: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uint]]
// CHECK: OpPhi [[ptr]]


