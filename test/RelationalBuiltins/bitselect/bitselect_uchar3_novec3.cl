// RUN: clspv  %s -o %t.spv -int8 -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global uchar3* a, global uchar3* b, global uchar3* c) {
  *a = bitselect(*a, *b, *c);
}

// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[char4:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 4
// CHECK: [[char_255:%[a-zA-Z0-9_]+]] = OpConstant [[char]] 255
// CHECK: [[char4_255_255_255:%[a-zA-Z0-9_]+]] = OpConstantComposite [[char4]] [[char_255]] [[char_255]] [[char_255]]
// CHECK: [[ld_a:%[a-zA-Z0-9_]+]] = OpLoad [[char4]]
// CHECK: [[ld_b:%[a-zA-Z0-9_]+]] = OpLoad [[char4]]
// CHECK: [[ld_c:%[a-zA-Z0-9_]+]] = OpLoad [[char4]]
// CHECK: [[xor:%[a-zA-Z0-9_]+]] = OpBitwiseXor [[char4]] [[ld_c]] [[char4_255_255_255]]
// CHECK: [[and1:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[char4]] [[ld_a]] [[xor]]
// CHECK: [[and2:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[char4]] [[ld_c]] [[ld_b]]
// CHECK: [[or:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[char4]] [[and1]] [[and2]]


