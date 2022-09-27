// RUN: clspv %target %s -o %t.spv -no-dra -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Full VariablePointers required because phi is between different buffers.
kernel void foo(global int* in1, global int* in2, global int* out, int a) {
  if (a == 0) {
    barrier(CLK_GLOBAL_MEM_FENCE);
    *out = *in1;
  } else {
    *out = *in2;
  }
}

// CHECK-NOT: OpCapability VariablePointersStorageBuffer
// CHECK-NOT: StorageBuffer
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uint]]
// CHECK: OpPhi [[ptr]]

