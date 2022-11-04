// RUN: clspv %target %s -o %t.spv -cl-native-math
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float3 *A, float3 x, float3 y) {
  *A = fmod(x,y);
}
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[_v4undef:%[^ ]+]] = OpUndef [[_v4float]]
// CHECK: [[_27:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_v4float]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_v4float]]
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpFRem [[_v4float]] [[_27]] [[_29]]
// CHECK: [[_shuffle30:%[^ ]+]] = OpVectorShuffle [[_v4float]] [[_30]] [[_v4undef]] 0 1 2 4294967295
// CHECK: OpStore {{.*}} [[_shuffle30]]
