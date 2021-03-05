// RUN: clspv %s -o %t.spv -cl-native-math
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float* A, float x, float y)
{
  *A = atan2pi(x, y);
}
// CHECK: [[_1:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_float_0_31831:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] 0.3183
// CHECK: [[_28:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]]
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]]
// CHECK: [[_31:%[a-zA-Z0-9_]+]] = OpExtInst [[_float]] [[_1]] Atan2 [[_28]] [[_30]]
// CHECK: [[_32:%[a-zA-Z0-9_]+]] = OpFMul [[_float]] [[_float_0_31831]] [[_31]]
// CHECK: OpStore {{.*}} [[_32]]
