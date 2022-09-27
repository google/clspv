// RUN: clspv %target %s -o %t.spv -g -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global uint *dst, global uint *srcA, global uint *srcB) {
  uint gid = get_global_id(0);
  if (srcA[gid] == 0)
      dst[gid] = srcB[gid];
  else
      dst[gid] = srcA[gid];
}

// CHECK:       OpAccessChain
// CHECK-NEXT:  OpLine [[filename:%[^ ]+]] 7 0
// CHECK-NEXT:  OpLoad
// CHECK-NEXT:  OpLine [[filename]] 0 0
// CHECK-NEXT:  OpNoLine
// CHECK-NEXT:  OpAccessChain
// CHECK-NEXT:  OpLine [[filename]] 8 0
// CHECK-NEXT:  OpLoad
// CHECK-NEXT:  OpIEqual
// CHECK-NEXT:  OpSelectionMerge
// CHECK-NEXT:  OpBranchConditional
// CHECK-NEXT:  OpLabel
// CHECK-NEXT:  OpNoLine
// CHECK-NEXT:  OpAccessChain
// CHECK-NEXT:  OpLine [[filename]] 9 0
// CHECK-NEXT:  OpLoad
// CHECK-NEXT:  OpBranch
// CHECK-NEXT:  OpLabel
// CHECK-NEXT:  OpLine [[filename]] 0 0
// CHECK-NEXT:  OpPhi
// CHECK-NEXT:  OpNoLine
// CHECK-NEXT:  OpAccessChain
// CHECK-NEXT:  OpLine [[filename]] 0 0
// CHECK-NEXT:  OpStore
// CHECK-NEXT:  OpLine [[filename]] 12 0
// CHECK-NEXT:  OpReturn

