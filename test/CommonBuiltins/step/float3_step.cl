// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float3 *A, float3 edge, float3 x) {
  *A = step(edge, x);
}
// CHECK: [[_1:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[_v3float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 3
// CHECK-DAG: [[undefv4:%[a-zA-Z0-9_]+]] = OpUndef [[_v4float]]
// CHECK-DAG: [[undefv3:%[a-zA-Z0-9_]+]] = OpUndef [[_v3float]]
// CHECK: [[_28:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_v4float]]
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_v4float]]
// CHECK: [[_28_shuffle:%[a-zA-Z0-9_]+]] = OpVectorShuffle [[_v3float]] [[_28]] [[undefv4]] 0 1 2
// CHECK: [[_30_shuffle:%[a-zA-Z0-9_]+]] = OpVectorShuffle [[_v3float]] [[_30]] [[undefv4]] 0 1 2
// CHECK: [[_31:%[a-zA-Z0-9_]+]] = OpExtInst [[_v3float]] [[_1]] Step [[_28_shuffle]] [[_30_shuffle]]
// CHECK: [[_31_shuffle:%[a-zA-Z0-9_]+]] = OpVectorShuffle [[_v4float]] [[_31]] [[undefv3]] 0 1 2 4294967295
// CHECK: OpStore {{.*}} [[_31_shuffle]]
