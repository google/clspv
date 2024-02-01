// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv
// TODO(#1292)
// XFAIL: *

// LLVM optimizes the selection to be between 1 and 2 and not pointers, so no
// variable pointers are required.
kernel void foo(local int* in, global int* out, int a) {
  local int* x = in + 1;
  local int* y = in + 2;
  local int* z = (a == 0) ? x : y;
  *out = *z;
}

// CHECK-NOT: OpCapability VariablePointers
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Workgroup [[uint]]
// CHECK-NOT: OpSelect [[ptr]]
