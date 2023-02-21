// RUN: clspv %target %s -o %t.spv --use-native-builtins=acospi
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float2* A, float2 x)
{
  *A = acospi(x);
}
// CHECK: [[_1:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v2float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_float_0_31831:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] 0.3183
// CHECK-DAG: [[_17:%[a-zA-Z0-9_]+]] = OpConstantComposite [[_v2float]] [[_float_0_31831]] [[_float_0_31831]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_v2float]]
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpExtInst [[_v2float]] [[_1]] Acos [[_29]]
// CHECK: [[_31:%[a-zA-Z0-9_]+]] = OpFMul [[_v2float]] [[_17]] [[_30]]
// CHECK: OpStore {{.*}} [[_31]]
