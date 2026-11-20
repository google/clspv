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
// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[sign_mask:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 9223372036854775808
// CHECK-DAG: %[[abs_mask:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 9223372036854775807
// CHECK:     %[[y:[0-9]+]] = OpBitcast %[[ulong]] {{.*}}
// CHECK:     %[[y_sign:[0-9]+]] = OpBitwiseAnd %[[ulong]] %[[y]] %[[sign_mask]]
// CHECK:     %[[x:[0-9]+]] = OpBitcast %[[ulong]] {{.*}}
// CHECK:     %[[x_abs:[0-9]+]] = OpBitwiseAnd %[[ulong]] %[[x]] %[[abs_mask]]
// CHECK:     %[[res:[0-9]+]] = OpBitwiseOr %[[ulong]] %[[x_abs]] %[[y_sign]]
// CHECK:     OpBitcast %[[double]] %[[res]]

void kernel test(global double* a, double b, double c) {
    *a = copysign(b, c);
}
