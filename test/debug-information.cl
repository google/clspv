// RUN: clspv %s -o %t.spv -g
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global uint *dst, global uint *src) {
  uint gid = get_global_id(0);
  dst[gid] = src[gid];
}

// CHECK:       OpAccessChain
// CHECK-NEXT:  OpLine [[filename:%[^ ]+]] 7 0
// CHECK-NEXT:  OpLoad
// CHECK-NEXT:  OpLine [[filename]] 0 0
// CHECK-NEXT:  OpNoLine
// CHECK-NEXT:  OpAccessChain
// CHECK-NEXT:  OpLine [[filename]] 8 0
// CHECK-NEXT:  OpLoad
// CHECK-NEXT:  OpNoLine
// CHECK-NEXT:  OpAccessChain
// CHECK-NEXT:  OpLine [[filename]] 8 0
// CHECK-NEXT:  OpStore
// CHECK-NEXT:  OpLine [[filename]] 9 0
// CHECK-NEXT:  OpReturn

