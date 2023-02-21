// RUN: clspv %target --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[FLOAT:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK: %[[FLOAT_ARRAY:[0-9a-zA-Z_]+]] = OpTypeArray %[[FLOAT]] %uint_8
// CHECK: %[[VOID:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK: OpFunction %[[VOID]]
// CHECK-COUNT-8: OpLoad %[[FLOAT]]
// CHECK: OpCompositeConstruct %[[FLOAT_ARRAY]]
// CHECK: %[[OP:[0-9a-zA-Z_]+]] = OpFunctionCall %[[FLOAT_ARRAY]]
// CHECK-COUNT-8: OpStore

void kernel test(global float8 *in, global float8 *out) {
  *out = exp2(*in);
}
