// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global long3* a, global long3* b) {
  *a = popcount(*b);
}

// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[int3:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 3
// CHECK: [[long:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK: [[long3:%[a-zA-Z0-9_]+]] = OpTypeVector [[long]] 3
// CHECK: [[long32:%[a-zA-Z0-9_]+]] = OpConstant [[long]] 32
// CHECK: [[long3_32:%[a-zA-Z0-9_]+]] = OpConstantComposite [[long3]] [[long32]] [[long32]]
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[long3]]
// CHECK: [[convert:%[a-zA-Z0-9_]+]] = OpUConvert [[int3]] [[ld]]
// CHECK: [[lowerbitcount:%[a-zA-Z0-9_]+]] = OpBitCount [[int3]] [[convert]]
// CHECK: [[upperld:%[a-zA-Z0-9_]+]] = OpShiftRightLogical [[long3]] [[ld]] [[long3_32]]
// CHECK: [[convert2:%[a-zA-Z0-9_]+]] = OpUConvert [[int3]] [[upperld]]
// CHECK: [[upperbitcount:%[a-zA-Z0-9_]+]] = OpBitCount [[int3]] [[convert2]]
// CHECK: [[bitcount:%[a-zA-Z0-9_]+]] = OpIAdd [[int3]] [[lowerbitcount]] [[upperbitcount]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpUConvert [[long3]] [[bitcount]]
// CHECK: OpStore {{.*}} [[cnt]]
