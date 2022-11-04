// RUN: clspv %target  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global char* a, global char* b, global char* c) {
  *a = bitselect(*a, *b, *c);
}

// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[char_255:%[a-zA-Z0-9_]+]] = OpConstant [[char]] 255
// CHECK: [[ld_a:%[a-zA-Z0-9_]+]] = OpLoad [[char]]
// CHECK: [[ld_b:%[a-zA-Z0-9_]+]] = OpLoad [[char]]
// CHECK: [[ld_c:%[a-zA-Z0-9_]+]] = OpLoad [[char]]
// CHECK: [[xor:%[a-zA-Z0-9_]+]] = OpBitwiseXor [[char]] [[ld_c]] [[char_255]]
// CHECK: [[and1:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[char]] [[ld_a]] [[xor]]
// CHECK: [[and2:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[char]] [[ld_c]] [[ld_b]]
// CHECK: [[or:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[char]] [[and1]] [[and2]]
