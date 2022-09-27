// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float* A, float x)
{
  *A = asinpi(x);
}
// CHECK: [[_1:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_float_0_31831:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] 0.3183
// CHECK: [[_27:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]]
// CHECK: [[_28:%[a-zA-Z0-9_]+]] = OpExtInst [[_float]] [[_1]] Asin [[_27]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpFMul [[_float]] [[_float_0_31831]] [[_28]]
// CHECK: OpStore {{.*}} [[_29]]
