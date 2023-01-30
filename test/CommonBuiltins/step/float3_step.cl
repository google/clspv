// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float3 *A, float3 edge, float3 x) {
  *A = step(edge, x);
}
// CHECK: [[_1:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v3float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 3
// CHECK: [[_28:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_v3float]]
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_v3float]]
// CHECK: [[_31:%[a-zA-Z0-9_]+]] = OpExtInst [[_v3float]] [[_1]] Step [[_28]] [[_30]]
// CHECK: OpStore {{.*}} [[_31]]
