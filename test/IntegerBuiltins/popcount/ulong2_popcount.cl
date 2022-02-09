// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global ulong2* a, global ulong2* b) {
  *a = popcount(*b);
}

// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[long:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK: [[long2:%[a-zA-Z0-9_]+]] = OpTypeVector [[long]] 2
// CHECK: [[int2:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 2
// CHECK: [[long32:%[a-zA-Z0-9_]+]] = OpConstant [[long]] 32
// CHECK: [[long2_32:%[a-zA-Z0-9_]+]] = OpConstantComposite [[long2]] [[long32]] [[long32]]
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[long2]]
// CHECK: [[convert:%[a-zA-Z0-9_]+]] = OpUConvert [[int2]] [[ld]]
// CHECK: [[lowerbitcount:%[a-zA-Z0-9_]+]] = OpBitCount [[int2]] [[convert]]
// CHECK: [[upperld:%[a-zA-Z0-9_]+]] = OpShiftRightLogical [[long2]] [[ld]] [[long2_32]]
// CHECK: [[convert2:%[a-zA-Z0-9_]+]] = OpUConvert [[int2]] [[upperld]]
// CHECK: [[upperbitcount:%[a-zA-Z0-9_]+]] = OpBitCount [[int2]] [[convert2]]
// CHECK: [[bitcount:%[a-zA-Z0-9_]+]] = OpIAdd [[int2]] [[lowerbitcount]] [[upperbitcount]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpUConvert [[long2]] [[bitcount]]
// CHECK: OpStore {{.*}} [[cnt]]
