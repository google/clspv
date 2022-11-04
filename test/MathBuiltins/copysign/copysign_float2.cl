// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[v2float:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 2
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v2uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 2
// CHECK-DAG: %[[uint_2147483648:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2147483648
// CHECK-DAG: %[[__original_id_17:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_2147483648]] %[[uint_2147483648]]
// CHECK-DAG: %[[uint_2147483647:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2147483647
// CHECK-DAG: %[[__original_id_19:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_2147483647]] %[[uint_2147483647]]
// CHECK:     %[[__original_id_35:[0-9]+]] = OpBitcast %[[v2uint]] %[[__original_id_34:[0-9]+]]
// CHECK:     %[[__original_id_36:[0-9]+]] = OpBitwiseAnd %[[v2uint]] %[[__original_id_35]] %[[__original_id_17]]
// CHECK:     %[[__original_id_37:[0-9]+]] = OpBitcast %[[v2uint]] %[[__original_id_32:[0-9]+]]
// CHECK:     %[[__original_id_38:[0-9]+]] = OpBitwiseAnd %[[v2uint]] %[[__original_id_37]] %[[__original_id_19]]
// CHECK:     %[[__original_id_39:[0-9]+]] = OpBitwiseOr %[[v2uint]] %[[__original_id_38]] %[[__original_id_36]]
// CHECK:     %[[__original_id_40:[0-9]+]] = OpBitcast %[[v2float]] %[[__original_id_39]]

void kernel test(global float2* a, float2 b, float2 c) {
    *a = copysign(b, c);
}

