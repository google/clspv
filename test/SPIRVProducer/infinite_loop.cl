// RUN: clspv %target %s -o %t.spv 2>&1 | FileCheck %s --check-prefix=WARN
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// WARN: warning: loop has no exit block

// CHECK: OpLoopMerge [[merge:%[a-zA-Z0-9_]+]] {{%[a-zA-Z0-9_]+}} None
// CHECK: [[merge]] = OpLabel
// CHECK-NEXT: OpUnreachable

kernel void infinite_loop(global int *out) {
  while (1) {
    *out = 1;
  }
}
