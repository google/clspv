// RUN: clspv  %s -S -o %t.spvasm -int8
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global char4* a, global char4* b, global uchar4* c) {
  *a = select(*a, *b, *c);
}

// CHECK-DAG: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK-DAG: [[char4:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 4
// CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[bool4:%[a-zA-Z0-9_]+]] = OpTypeVector [[bool]] 4
// CHECK: [[null:%[a-zA-Z0-9_]+]] = OpConstantNull [[char4]]
// CHECK: [[ld_a:%[a-zA-Z0-9_]+]] = OpLoad [[char4]]
// CHECK: [[ld_b:%[a-zA-Z0-9_]+]] = OpLoad [[char4]]
// CHECK: [[ld_c:%[a-zA-Z0-9_]+]] = OpLoad [[char4]]
// CHECK: [[less:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool4]] [[ld_c]] [[null]]
// CHECK: OpSelect [[char4]] [[less]] [[ld_b]] [[ld_a]]

