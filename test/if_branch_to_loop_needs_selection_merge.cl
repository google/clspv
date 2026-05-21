// RUN: clspv -arch=spirv32 %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv -arch=spirv64 %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpLabel
// CHECK-NOT OpLabel
// CHECK: OpSelectionMerge [[smerge:%[a-zA-Z0-9_]+]]
// CHECK-NEXT: OpBranchConditional {{.*}} [[loop:%[a-zA-Z0-9_]+]] [[smerge]]
// CHECK-64: [[loop]] = OpLabel
// CHECK-64: OpBranch [[loop:%[a-zA-Z0-9_]+]]
// CHECK: [[loop]] = OpLabel
// CHECK-NOT: OpLabel
// CHECK: OpLoopMerge [[lmerge:%[a-zA-Z0-9_]+]]
// CHECK: [[lmerge]] = OpLabel
// CHECK-NEXT: OpBranch [[smerge]]

__kernel void foo(global int* a, global int *b, int m, int n) {
  if (m > 0) {
    for (int i = 0; i < n; ++i) {
      a[i] += b[i];
    }
  }
}

