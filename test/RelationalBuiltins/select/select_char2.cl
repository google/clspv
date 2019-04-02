// RUN: clspv  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global char2* a, global char2* b, global uchar2* c) {
  *a = select(*a, *b, *c);
}

// CHECK-DAG: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK-DAG: [[char2:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 2
// CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[bool2:%[a-zA-Z0-9_]+]] = OpTypeVector [[bool]] 2
// CHECK: [[null:%[a-zA-Z0-9_]+]] = OpConstantNull [[char2]]
// CHECK: [[ld_a:%[a-zA-Z0-9_]+]] = OpLoad [[char2]]
// CHECK: [[ld_b:%[a-zA-Z0-9_]+]] = OpLoad [[char2]]
// CHECK: [[ld_c:%[a-zA-Z0-9_]+]] = OpLoad [[char2]]
// CHECK: [[less:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool2]] [[ld_c]] [[null]]
// CHECK: OpSelect [[char2]] [[less]] [[ld_b]] [[ld_a]]
