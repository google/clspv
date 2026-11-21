// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t3.spv --use-native-builtins=copysign
// RUN: spirv-dis -o %t4.spvasm %t3.spv
// RUN: FileCheck %s < %t4.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t3.spv

// The sign bit mask is 0x8000000000000000 and its complement is
// 0x7fffffffffffffff.
// CHECK-DAG: %[[double:[0-9a-zA-Z_]+]] = OpTypeFloat 64
// CHECK-DAG: %[[v4double:[0-9a-zA-Z_]+]] = OpTypeVector %[[double]] 4
// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v4ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 4
// CHECK-DAG: %[[ulong_sign_mask:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 9223372036854775808
// CHECK-DAG: %[[sign_mask:[0-9a-zA-Z_]+]] = OpConstantComposite %[[v4ulong]] %[[ulong_sign_mask]] %[[ulong_sign_mask]] %[[ulong_sign_mask]] %[[ulong_sign_mask]]
// CHECK-DAG: %[[ulong_abs_mask:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 9223372036854775807
// CHECK-DAG: %[[abs_mask:[0-9a-zA-Z_]+]] = OpConstantComposite %[[v4ulong]] %[[ulong_abs_mask]] %[[ulong_abs_mask]] %[[ulong_abs_mask]] %[[ulong_abs_mask]]
// CHECK:     %[[y:[0-9]+]] = OpBitcast %[[v4ulong]] {{.*}}
// CHECK:     %[[y_sign:[0-9]+]] = OpBitwiseAnd %[[v4ulong]] %[[y]] %[[sign_mask]]
// CHECK:     %[[x:[0-9]+]] = OpBitcast %[[v4ulong]] {{.*}}
// CHECK:     %[[x_abs:[0-9]+]] = OpBitwiseAnd %[[v4ulong]] %[[x]] %[[abs_mask]]
// CHECK:     %[[res:[0-9]+]] = OpBitwiseOr %[[v4ulong]] %[[x_abs]] %[[y_sign]]
// CHECK:     OpBitcast %[[v4double]] %[[res]]

void kernel test(global double4* a, double4 b, double4 c) {
    *a = copysign(b, c);
}
