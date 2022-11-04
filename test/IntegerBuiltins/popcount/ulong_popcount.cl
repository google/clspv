// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global ulong* a, global ulong* b) {
  *a = popcount(*b);
}

// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[long:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK: [[long32:%[a-zA-Z0-9_]+]] = OpConstant [[long]] 32
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[long]]
// CHECK: [[convert:%[a-zA-Z0-9_]+]] = OpUConvert [[int]] [[ld]]
// CHECK: [[lowerbitcount:%[a-zA-Z0-9_]+]] = OpBitCount [[int]] [[convert]]
// CHECK: [[upperld:%[a-zA-Z0-9_]+]] = OpShiftRightLogical [[long]] [[ld]] [[long32]]
// CHECK: [[convert2:%[a-zA-Z0-9_]+]] = OpUConvert [[int]] [[upperld]]
// CHECK: [[upperbitcount:%[a-zA-Z0-9_]+]] = OpBitCount [[int]] [[convert2]]
// CHECK: [[bitcount:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] [[lowerbitcount]] [[upperbitcount]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpUConvert [[long]] [[bitcount]]
// CHECK: OpStore {{.*}} [[cnt]]
