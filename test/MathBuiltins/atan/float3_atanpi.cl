// RUN: clspv %s -o %t.spv -cl-native-math
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float3* A, float3 x)
{
  *A = atanpi(x);
}
// CHECK: [[_1:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[_v4undef:%[^ ]+]] = OpUndef [[_v4float]]
// CHECK-DAG: [[_float_0_31831:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] 0.3183
// CHECK-DAG: [[_17:%[a-zA-Z0-9_]+]] = OpConstantComposite [[_v4float]] [[_float_0_31831]] [[_float_0_31831]] [[_float_0_31831]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_v4float]]
// CHECK: [[_shuffle:%[^ ]+]] = OpVectorShuffle [[_v4float]] [[_29]] [[_v4undef]] 0 1 2 4294967295
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpExtInst [[_v4float]] [[_1]] Atan [[_shuffle]]
// CHECK: [[_31:%[a-zA-Z0-9_]+]] = OpFMul [[_v4float]] [[_17]] [[_30]]
// CHECK: OpStore {{.*}} [[_31]]
