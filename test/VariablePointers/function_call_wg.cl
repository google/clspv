// RUN: clspv %target %s -o %t.spv -no-dra -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Pass base workgroup object to a function shouldn't require variable
// pointers, but the representation inserts an OpAccessChain so we require
// VariablePointers because it is NOT a memory object declaration.
__attribute__((noinline))
int bar(local int* x) { return *x; }

kernel void foo(local int* in, global int* out) {
  *out = bar(in);
}

// CHECK-NOT: OpCapability VariablePointersStorageBuffer
// CHECK: OpCapability VariablePointers
// CHECK-NOT: StorageBuffer
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Workgroup [[uint]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]]
// CHECK: OpFunctionCall [[uint]] {{.*}} [[gep]]

