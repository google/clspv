// RUN: clspv %s -o %t.spv -cl-native-math
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float *A, float x, float y) {
  *A = fmod(x,y);
}
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[_26:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]]
// CHECK: [[_28:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpFRem [[_float]] [[_26]] [[_28]]
// CHECK: OpStore {{.*}} [[_29]]
