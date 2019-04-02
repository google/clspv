// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[v3float:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 3
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v3uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 3
// CHECK-DAG: %[[uint_2147483648:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2147483648
// CHECK-DAG: %[[__original_id_16:[0-9]+]] = OpConstantComposite %[[v3uint]] %[[uint_2147483648]] %[[uint_2147483648]] %[[uint_2147483648]]
// CHECK-DAG: %[[uint_2147483647:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2147483647
// CHECK-DAG: %[[__original_id_18:[0-9]+]] = OpConstantComposite %[[v3uint]] %[[uint_2147483647]] %[[uint_2147483647]] %[[uint_2147483647]]
// CHECK:     %[[__original_id_34:[0-9]+]] = OpBitcast %[[v3uint]] %[[__original_id_33:[0-9]+]]
// CHECK:     %[[__original_id_35:[0-9]+]] = OpBitwiseAnd %[[v3uint]] %[[__original_id_34]] %[[__original_id_16]]
// CHECK:     %[[__original_id_36:[0-9]+]] = OpBitcast %[[v3uint]] %[[__original_id_31:[0-9]+]]
// CHECK:     %[[__original_id_37:[0-9]+]] = OpBitwiseAnd %[[v3uint]] %[[__original_id_36]] %[[__original_id_18]]
// CHECK:     %[[__original_id_38:[0-9]+]] = OpBitwiseOr %[[v3uint]] %[[__original_id_35]] %[[__original_id_37]]
// CHECK:     %[[__original_id_39:[0-9]+]] = OpBitcast %[[v3float]] %[[__original_id_38]]

void kernel test(global float3* a, float3 b, float3 c) {
    *a = copysign(b, c);
}

