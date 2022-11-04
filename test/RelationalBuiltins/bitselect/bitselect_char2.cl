// RUN: clspv %target  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global char2* a, global char2* b, global char2* c) {
  *a = bitselect(*a, *b, *c);
}

// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[char2:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 2
// CHECK: [[char_255:%[a-zA-Z0-9_]+]] = OpConstant [[char]] 255
// CHECK: [[char2_255_255:%[a-zA-Z0-9_]+]] = OpConstantComposite [[char2]] [[char_255]] [[char_255]]
// CHECK: [[ld_a:%[a-zA-Z0-9_]+]] = OpLoad [[char2]]
// CHECK: [[ld_b:%[a-zA-Z0-9_]+]] = OpLoad [[char2]]
// CHECK: [[ld_c:%[a-zA-Z0-9_]+]] = OpLoad [[char2]]
// CHECK: [[xor:%[a-zA-Z0-9_]+]] = OpBitwiseXor [[char2]] [[ld_c]] [[char2_255_255]]
// CHECK: [[and1:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[char2]] [[ld_a]] [[xor]]
// CHECK: [[and2:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[char2]] [[ld_c]] [[ld_b]]
// CHECK: [[or:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[char2]] [[and1]] [[and2]]
