// RUN: clspv --long-vector %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int* a, global long16* b) {
  *a = any(*b);
}

// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[long:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[int_16:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 16
// CHECK-DAG: [[int_0:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK-DAG: [[int_1:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 1
// CHECK-DAG: [[long0:%[a-zA-Z0-9_]+]] = OpConstant [[long]] 0
// CHECK-DAG: [[bool4:%[a-zA-Z0-9_]+]] = OpTypeVector [[bool]] 4
// CHECK:     [[vec10:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]] {{.*}} [[long0]]
// CHECK:     [[vec11:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]] {{.*}} [[long0]]
// CHECK:     [[vec12:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]] {{.*}} [[long0]]
// CHECK:     [[vec13:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]] {{.*}} [[long0]]
// CHECK:     [[vec20:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]] {{.*}} [[long0]]
// CHECK:     [[vec21:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]] {{.*}} [[long0]]
// CHECK:     [[vec22:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]] {{.*}} [[long0]]
// CHECK:     [[vec23:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]] {{.*}} [[long0]]
// CHECK:     [[vec30:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]] {{.*}} [[long0]]
// CHECK:     [[vec31:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]] {{.*}} [[long0]]
// CHECK:     [[vec32:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]] {{.*}} [[long0]]
// CHECK:     [[vec33:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]] {{.*}} [[long0]]
// CHECK:     [[vec40:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]] {{.*}} [[long0]]
// CHECK:     [[vec41:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]] {{.*}} [[long0]]
// CHECK:     [[vec42:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]] {{.*}} [[long0]]
// CHECK:     [[vec43:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]] {{.*}} [[long0]]
// CHECK:     [[vec1:%[a-zA-Z0-9_]+]] = OpCompositeConstruct [[bool4]] [[vec10]] [[vec11]] [[vec12]] [[vec13]]
// CHECK:     [[any1:%[a-zA-Z0-9_]+]] = OpAny [[bool]] [[vec1]]
// CHECK:     [[vec2:%[a-zA-Z0-9_]+]] = OpCompositeConstruct [[bool4]] [[vec20]] [[vec21]] [[vec22]] [[vec23]]
// CHECK:     [[any2:%[a-zA-Z0-9_]+]] = OpAny [[bool]] [[vec2]]
// CHECK:     [[and12:%[a-zA-Z0-9_]+]] = OpLogicalOr [[bool]] [[any1]] [[any2]]
// CHECK:     [[vec3:%[a-zA-Z0-9_]+]] = OpCompositeConstruct [[bool4]] [[vec30]] [[vec31]] [[vec32]] [[vec33]]
// CHECK:     [[any3:%[a-zA-Z0-9_]+]] = OpAny [[bool]] [[vec3]]
// CHECK:     [[and123:%[a-zA-Z0-9_]+]] = OpLogicalOr [[bool]] [[and12]] [[any3]]
// CHECK:     [[vec4:%[a-zA-Z0-9_]+]] = OpCompositeConstruct [[bool4]] [[vec40]] [[vec41]] [[vec42]] [[vec43]]
// CHECK:     [[any4:%[a-zA-Z0-9_]+]] = OpAny [[bool]] [[vec4]]
// CHECK:     [[and:%[a-zA-Z0-9_]+]] = OpLogicalOr [[bool]] [[and123]] [[any4]]
// CHECK:     OpSelect [[int]] [[and]] [[int_1]] [[int_0]]

