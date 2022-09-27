// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global long4* a, global long4* b) {
  *a = popcount(*b);
}

// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[long:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK: [[long4:%[a-zA-Z0-9_]+]] = OpTypeVector [[long]] 4
// CHECK: [[int4:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 4
// CHECK: [[long32:%[a-zA-Z0-9_]+]] = OpConstant [[long]] 32
// CHECK: [[long4_32:%[a-zA-Z0-9_]+]] = OpConstantComposite [[long4]] [[long32]] [[long32]]
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[long4]]
// CHECK: [[convert:%[a-zA-Z0-9_]+]] = OpUConvert [[int4]] [[ld]]
// CHECK: [[lowerbitcount:%[a-zA-Z0-9_]+]] = OpBitCount [[int4]] [[convert]]
// CHECK: [[upperld:%[a-zA-Z0-9_]+]] = OpShiftRightLogical [[long4]] [[ld]] [[long4_32]]
// CHECK: [[convert2:%[a-zA-Z0-9_]+]] = OpUConvert [[int4]] [[upperld]]
// CHECK: [[upperbitcount:%[a-zA-Z0-9_]+]] = OpBitCount [[int4]] [[convert2]]
// CHECK: [[bitcount:%[a-zA-Z0-9_]+]] = OpIAdd [[int4]] [[lowerbitcount]] [[upperbitcount]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpUConvert [[long4]] [[bitcount]]
// CHECK: OpStore {{.*}} [[cnt]]
