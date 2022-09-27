// RUN: clspv %target %s -o %t.spv -cl-native-math
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float3* A, global float3* B, float3 x)
{
  float3 z;
  *A = fract(x, &z);
  *B = z;
}
// CHECK: [[_1:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[_v4undef:%[^ ]+]] = OpUndef [[_v4float]]
// CHECK-DAG: [[_float_1:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] {{1|0.99999}}
// CHECK-DAG: [[_17:%[a-zA-Z0-9_]+]] = OpConstantComposite [[_v4float]] [[_float_1]] [[_float_1]] [[_float_1]]
// CHECK: [[_28:%[a-zA-Z0-9_]+]] = OpAccessChain
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpAccessChain
// CHECK: [[_31:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_v4float]]
// CHECK: [[_shuffle31:%[^ ]+]] = OpVectorShuffle [[_v4float]] [[_31]] [[_v4undef]] 0 1 2 4294967295
// CHECK: [[_32:%[a-zA-Z0-9_]+]] = OpExtInst [[_v4float]] [[_1]] Floor [[_shuffle31]]
// CHECK: [[_33:%[a-zA-Z0-9_]+]] = OpExtInst [[_v4float]] [[_1]] Fract [[_shuffle31]]
// CHECK: [[_34:%[a-zA-Z0-9_]+]] = OpExtInst [[_v4float]] [[_1]] NMin [[_33]] [[_17]]
// CHECK: OpStore [[_28]] [[_34]]
// CHECK: OpStore [[_29]] [[_32]]
