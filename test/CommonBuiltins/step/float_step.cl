// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float *A, float edge, float x) {
  *A = step(edge, x);
}
// CHECK: [[_1:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[_27:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]]
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpExtInst [[_float]] [[_1]] Step [[_27]] [[_29]]
// CHECK: OpStore {{.*}} [[_30]]
