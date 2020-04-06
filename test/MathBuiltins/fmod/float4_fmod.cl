// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float4 *A, float4 x, float4 y) {
  *A = fmod(x,y);
}
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 4
// CHECK: [[_27:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_v4float]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_v4float]]
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpFRem [[_v4float]] [[_27]] [[_29]]
// CHECK: OpStore {{.*}} [[_30]]
