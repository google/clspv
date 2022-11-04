// RUN: clspv %target %s -o %t.spv -no-dra -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// The OpPtrAccessChain requires VariablePointers for Workgorup. So does passing
// the of the argument though...
__attribute__((noinline))
int bar(local int* x) { return x[1]; }
kernel void foo(local int* in, global int* out) {
  *out = bar(in);
}

// CHECK-NOT: OpCapability VariablePointersStorageBuffer
// CHECK: OpCapability VariablePointers
// CHECK-NOT: StorageBuffer
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Workgroup [[uint]]
// CHECK: OpPtrAccessChain [[ptr]]


