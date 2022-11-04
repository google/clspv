// RUN: clspv %target %s -o %t.spv -no-dra -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Passing SSBO to function call requires VariablePointersStorageBuffer.
// SSBO args do not require memory object declarations.
__attribute__((noinline))
int bar(global int* x) { return *x; }

kernel void foo(global int* in, global int* out) {
  *out = bar(in + 1);
}

// CHECK-NOT: OpCapability VariablePointers
// CHECK: OpCapability VariablePointersStorageBuffer
// CHECK-NOT: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uint]]
// CHECK: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] {{.*}} [[uint_0]] [[uint_1]]
// CHECK-NEXT: OpFunctionCall [[uint]] {{.*}} [[gep]]

