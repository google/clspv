// RUN: clspv %s -o %t.spv -cl-native-math
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float2* A, float2 y, float2 x)
{
  *A = atan2pi(y, x);
}
// CHECK: [[_1:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v2float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_float_0_31831:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] 0.3183
// CHECK-DAG: [[_17:%[a-zA-Z0-9_]+]] = OpConstantComposite [[_v2float]] [[_float_0_31831]] [[_float_0_31831]]
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_v2float]]
// CHECK: [[_32:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_v2float]]
// CHECK: [[_33:%[a-zA-Z0-9_]+]] = OpExtInst [[_v2float]] [[_1]] Atan2 [[_30]] [[_32]]
// CHECK: [[_34:%[a-zA-Z0-9_]+]] = OpFMul [[_v2float]] [[_17]] [[_33]]
// CHECK: OpStore {{.*}} [[_34]]
