// RUN: clspv %s -o %t.spv -no-dra -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// This should only require VariablePointersStorageBuffer, but the structurizer
// does some funny things with the if statement and we end up with two
// conditional branches.
kernel void foo(global int* in, global int* out, int a) {
  if (a == 0) {
    barrier(CLK_GLOBAL_MEM_FENCE);
    *out = *(in + 1);
  } else {
    *out = *(in + 2);
  }
}

// CHECK-NOT: StorageBuffer
// CHECK: OpCapability VariablePointersStorageBuffer
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uint]]
// CHECK: OpPhi [[ptr]]



