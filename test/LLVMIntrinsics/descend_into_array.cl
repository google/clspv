// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct {
  int4 x;
} inner;

typedef struct {
  inner i[2];
} outer;

__kernel void foo(__global outer* out, global outer* in) {
  out->i[0] = in->i[0];
}

// CHECK: [[zero:%[0-9a-zA-Z_]+]] = OpConstant {{.*}} 0
// CHECK: [[dst:%[0-9a-zA-Z_]+]] = OpVariable {{.*}} StorageBuffer
// CHECK: [[src:%[0-9a-zA-Z_]+]] = OpVariable {{.*}} StorageBuffer
// CHECK: [[src_gep:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[src]] [[zero]] [[zero]]
// CHECK: [[dst_gep:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[dst]] [[zero]] [[zero]]
// CHECK: OpCopyMemory [[dst_gep]] [[src_gep]] Aligned 16
