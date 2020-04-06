// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uint_2147483648:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2147483648
// CHECK-DAG: %[[uint_2147483647:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2147483647
// CHECK:     %[[__original_id_30:[0-9]+]] = OpBitcast %[[uint]] {{.*}}
// CHECK:     %[[__original_id_31:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_30]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_32:[0-9]+]] = OpBitcast %[[uint]] {{.*}}
// CHECK:     %[[__original_id_33:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_32]] %[[uint_2147483647]]
// CHECK:     %[[__original_id_34:[0-9]+]] = OpBitwiseOr %[[uint]] %[[__original_id_33]] %[[__original_id_31]]
// CHECK:     %[[__original_id_35:[0-9]+]] = OpBitcast %[[float]] %[[__original_id_34]]

void kernel test(global float* a, float b, float c) {
    *a = copysign(b, c);
}

